"""
dimension_aware_refinement method: dimension-aware clarification over a
candidate edit pool.

This method:
1. Generates a parent spec and a pool of interpretation candidates
2. Allocates the remaining interaction budget across dimensions from that pool
3. Expands the allocation into a grouped round schedule
4. Samples one candidate from the scheduled dimension each round
5. Converts the chosen candidate into a yes/no clarification question
6. Prunes conflicting candidates from the pool based on the observed answer
7. Regenerates the parent spec and candidate pool from prompt + Q/A history
   when the current pool is empty or the scheduled dimension has no available
   candidates
8. Generates the final spec from prompt + Q/A history after the budget ends
"""

from __future__ import annotations

import json
import random
import re
from dataclasses import dataclass
from typing import Any, Callable, Dict

from src.config import make_llm
from src.edit_actions import EditAction, parse_edits
from src.methods.direct_random_q import build_clarified_intent
from src.methods.direct_random_q_anno import generate_questions, QUESTION_GENERATOR_SYSTEM_PROMPT
from src.methods.weighted_utils import compute_final_weights, compute_question_budget
from src.spec_generator import SpecGenerator
from src.user_proxy import UserProxy
from src.utils.utils import is_awscc


@dataclass
class RefinementCandidate:
    dimension: str
    actions: list[EditAction]


def _parse_spec(raw_spec: str) -> dict:
    """Parse a raw spec string into a dict with guaranteed keys."""
    try:
        spec = json.loads(raw_spec)
    except (json.JSONDecodeError, ValueError):
        spec = {}

    if not isinstance(spec, dict):
        spec = {}

    resources = spec.get("resources", {})
    topology = spec.get("topology", {})
    attributes = spec.get("attributes", {})

    if not isinstance(resources, dict):
        resources = {}

    if not isinstance(topology, dict):
        topology = {}

    if not isinstance(attributes, dict):
        attributes = {}

    return {
        "resources": resources,
        "topology": topology,
        "attributes": attributes,
    }


def _serialize_action(action: EditAction) -> dict[str, Any]:
    """Convert an edit action into a JSON-serializable dict."""
    return {
        "op": action.op,
        "field": action.field,
        "value": action.value,
        "json_value": action.json_value,
    }


def _serialize_candidate(candidate: RefinementCandidate) -> dict[str, Any]:
    """Convert a candidate into a JSON-serializable dict."""
    return {
        "dimension": candidate.dimension,
        "actions": [_serialize_action(action) for action in candidate.actions],
    }


def _action_key(action: EditAction) -> str:
    """Build a stable identity for an atomic edit action."""
    return json.dumps(_serialize_action(action), sort_keys=True)


def _candidate_action_keys(candidate: RefinementCandidate) -> set[str]:
    """Return the exact signed atomic edits represented by this candidate."""
    return {_action_key(action) for action in candidate.actions}


def _candidate_key(candidate: RefinementCandidate) -> str:
    """Build a stable identity for a candidate proposition."""
    if candidate.dimension == "attribute":
        return _action_key(candidate.actions[0])

    return json.dumps(
        {
            "dimension": candidate.dimension,
            "actions": sorted(_candidate_action_keys(candidate)),
        },
        sort_keys=True,
    )


def _count_dimensions(candidates: list[RefinementCandidate]) -> dict[str, int]:
    """Count candidates by dimension."""
    counts = {
        "resource": 0,
        "topology": 0,
        "attribute": 0,
    }

    for candidate in candidates:
        if candidate.dimension in counts:
            counts[candidate.dimension] += 1

    return counts


def _build_dimension_schedule(budget: dict[str, int], random_shuffle: bool = False) -> list[str]:
    """Expand a dimension budget into grouped per-round schedule entries."""
    schedule: list[str] = []
    for dim in ("resource", "topology", "attribute"):
        schedule.extend([dim] * budget.get(dim, 0))
    if random_shuffle:
        random.shuffle(schedule)
    return schedule


def _build_pool_budget(
    candidates: list[RefinementCandidate],
    remaining_rounds: int,
    ratios: tuple[int, int, int],
    skip_prior_weighting: bool,
) -> tuple[dict[str, int], dict[str, int], dict[str, int]]:
    """Compute runtime counts, final weights, and grouped schedule budget."""
    runtime_weights = _count_dimensions(candidates)

    if skip_prior_weighting:
        final_weights = dict(runtime_weights)
    else:
        final_weights = compute_final_weights(runtime_weights, prior=ratios)

    budget = compute_question_budget(remaining_rounds, final_weights)
    return runtime_weights, final_weights, budget


def _split_interpretation_blocks(text: str) -> list[str]:
    """Split interpretation output into candidate blocks."""
    blocks: list[str] = []
    current: list[str] = []

    for raw_line in text.splitlines():
        line = raw_line.strip()

        if re.match(r"^###\s+Interpretation\b", line):
            if current:
                blocks.append("\n".join(current).strip())
                current = []
            continue

        if not line:
            if current:
                blocks.append("\n".join(current).strip())
                current = []
            continue

        current.append(line)

    if current:
        blocks.append("\n".join(current).strip())

    if blocks:
        return [block for block in blocks if block]

    fallback = text.strip()
    return [fallback] if fallback else []


def _dedupe_actions(actions: list[EditAction]) -> list[EditAction]:
    """Remove repeated atomic edits while preserving the original order."""
    deduped: list[EditAction] = []
    seen = set()

    for action in actions:
        key = _action_key(action)

        if key in seen:
            continue

        seen.add(key)
        deduped.append(action)

    return deduped


def _candidate_contains(
    candidate: RefinementCandidate,
    selected: RefinementCandidate,
) -> bool:
    """Whether candidate contains the full selected resource/topology bundle."""
    return _candidate_action_keys(selected).issubset(_candidate_action_keys(candidate))


def _prune_candidates(
    pool: list[RefinementCandidate],
    chosen_candidate: RefinementCandidate,
    observed_answer: bool | None,
) -> list[RefinementCandidate]:
    """Prune the current pool according to the chosen candidate and answer."""
    if observed_answer is None:
        return list(pool)

    chosen_key = _candidate_key(chosen_candidate)
    pruned: list[RefinementCandidate] = []

    for candidate in pool:
        # Attribute rounds stay local: only the chosen edit survives or drops.
        if chosen_candidate.dimension == "attribute":
            if candidate.dimension != "attribute":
                pruned.append(candidate)
                continue

            if _candidate_key(candidate) == chosen_key:
                if observed_answer is True:
                    pruned.append(candidate)
                continue

            pruned.append(candidate)
            continue

        if candidate.dimension == "attribute":
            pruned.append(candidate)
            continue

        contains_selected = _candidate_contains(candidate, chosen_candidate)

        if observed_answer is True:
            if contains_selected:
                pruned.append(candidate)
            continue

        if not contains_selected:
            pruned.append(candidate)

    return pruned


def _render_edit_target(action: EditAction) -> str:
    """Render the target object of an atomic edit."""
    if action.field == "resource":
        return f"resource {action.value}"

    if action.field == "topology":
        return f"topology {action.value}"

    if action.field == "attribute" and action.json_value is not None:
        attrs = json.dumps(action.json_value, sort_keys=True)
        return f'attribute {action.value} with {attrs}'

    if action.field == "attribute":
        return f"attribute {action.value}"

    return action.value


def _render_desired_state_phrase(action: EditAction) -> str:
    """Render one atomic edit as desired end-state language."""
    target = _render_edit_target(action)

    if action.op == "add":
        return f"have {target}"

    return f"not have {target}"


def _generate_question_from_candidate(candidate: RefinementCandidate) -> str:
    """Convert one candidate directly into a yes/no clarification question."""
    if len(candidate.actions) == 1:
        return f"Should it {_render_desired_state_phrase(candidate.actions[0])}?"

    states = " and ".join(
        _render_desired_state_phrase(action) for action in candidate.actions
    )
    return f"Should it {states}?"


def _filter_already_asked_candidates(
    pool: list[RefinementCandidate],
    asked_bundle_keys: set[str],
    asked_attribute_keys: set[str],
) -> list[RefinementCandidate]:
    """Drop propositions that have already been asked about in earlier rounds."""
    filtered: list[RefinementCandidate] = []

    for candidate in pool:
        key = _candidate_key(candidate)

        if candidate.dimension == "attribute":
            if key in asked_attribute_keys:
                continue
        elif key in asked_bundle_keys:
            continue

        filtered.append(candidate)

    return filtered


def _available_candidates(
    pool: list[RefinementCandidate],
    current_dim: str,
    asked_bundle_keys: set[str],
    asked_attribute_keys: set[str],
) -> list[RefinementCandidate]:
    """Return same-dimension candidates that have not already been asked about."""
    available: list[RefinementCandidate] = []

    for candidate in pool:
        if candidate.dimension != current_dim:
            continue

        key = _candidate_key(candidate)

        if current_dim == "attribute":
            if key in asked_attribute_keys:
                continue
        elif key in asked_bundle_keys:
            continue

        available.append(candidate)

    return available


def _regeneration_reason(
    pool: list[RefinementCandidate],
    current_dim: str,
    asked_bundle_keys: set[str],
    asked_attribute_keys: set[str],
) -> str | None:
    """Return the regeneration reason for the current round, if any."""
    if not pool:
        return "empty_pool_with_budget_remaining"

    if not _available_candidates(
        pool,
        current_dim,
        asked_bundle_keys,
        asked_attribute_keys,
    ):
        return f"no_{current_dim}_actions_for_scheduled_round"

    return None


def _choose_candidate(candidates: list[RefinementCandidate]) -> RefinementCandidate:
    """Select one candidate from the currently available same-dimension pool."""
    return random.choice(candidates)


def _candidate_dimension(actions: list[EditAction]) -> str | None:
    """Assign one operating dimension to a bundle by resource/topology/attribute priority."""
    fields = {action.field for action in actions}

    if "resource" in fields:
        return "resource"

    if "topology" in fields:
        return "topology"

    if "attribute" in fields:
        return "attribute"

    return None


def _build_candidates_from_block(block: str) -> list[RefinementCandidate]:
    """Convert one raw interpretation block into one bundle or attribute singletons."""
    actions = _dedupe_actions([
        action
        for action in parse_edits(block)
        if action.field in {"resource", "topology", "attribute"}
    ])

    if not actions:
        return []

    dimension = _candidate_dimension(actions)

    if dimension != "attribute":
        return [
            RefinementCandidate(
                dimension=dimension,
                actions=actions,
            )
        ]

    return [
        RefinementCandidate(
            dimension="attribute",
            actions=[action],
        )
        for action in actions
    ]


def _generate_action_pool(
    spec_gen: SpecGenerator,
    prompt: str,
    questions: list[str],
    answers: list[bool | None],
) -> tuple[dict, list[RefinementCandidate], dict[str, Any]]:
    """Generate a parent spec and a deduped interpretation candidate pool."""
    clarified_intent = ""

    if questions or answers:
        clarified_intent = build_clarified_intent(prompt, questions, answers)

    parent_spec = _parse_spec(spec_gen.generate_spec(prompt, feedback=clarified_intent))
    raw_actions = spec_gen.generate_interpretation_edits(
        prompt,
        parent_spec,
        clarified_intent=clarified_intent,
    )
    candidate_blocks = _split_interpretation_blocks(raw_actions)

    candidates: list[RefinementCandidate] = []

    for block in candidate_blocks:
        candidates.extend(_build_candidates_from_block(block))

    deduped_candidates: list[RefinementCandidate] = []
    seen = set()

    for candidate in candidates:
        key = _candidate_key(candidate)

        if key in seen:
            continue

        seen.add(key)
        deduped_candidates.append(candidate)

    return (
        parent_spec,
        deduped_candidates,
        {
            "clarified_intent": clarified_intent,
            "parent_spec": json.loads(json.dumps(parent_spec)),
            "raw_edit_actions": raw_actions,
            "candidate_blocks": list(candidate_blocks),
            "parsed_candidates": [
                _serialize_candidate(candidate) for candidate in deduped_candidates
            ],
        },
    )


def _apply_history_to_pool(
    pool: list[RefinementCandidate],
    asked_history: list[tuple[RefinementCandidate, bool | None]],
) -> list[RefinementCandidate]:
    """Replay prior answers so regenerated pools honor the learned constraints."""
    pruned_pool = list(pool)

    for chosen_candidate, observed_answer in asked_history:
        pruned_pool = _prune_candidates(
            pruned_pool,
            chosen_candidate,
            observed_answer,
        )

    return pruned_pool


def _refresh_pool_and_schedule(
    spec_gen: SpecGenerator,
    prompt: str,
    questions: list[str],
    answers: list[bool | None],
    asked_history: list[tuple[RefinementCandidate, bool | None]],
    asked_bundle_keys: set[str],
    asked_attribute_keys: set[str],
    remaining_rounds: int,
    ratios: tuple[int, int, int],
    skip_prior_weighting: bool,
    regeneration_reason: str,
    event_index: int,
    random_shuffle: bool = False,
) -> tuple[list[RefinementCandidate], list[str], dict[str, Any]]:
    """Regenerate the candidate pool and build a fresh remaining-round schedule."""
    _, pool_candidates, pool_trace = _generate_action_pool(
        spec_gen,
        prompt,
        questions,
        answers,
    )
    pool_candidates = _apply_history_to_pool(pool_candidates, asked_history)
    pool_candidates = _filter_already_asked_candidates(
        pool_candidates,
        asked_bundle_keys,
        asked_attribute_keys,
    )
    runtime_weights, final_weights, budget = _build_pool_budget(
        pool_candidates,
        remaining_rounds,
        ratios,
        skip_prior_weighting,
    )
    schedule = _build_dimension_schedule(budget, random_shuffle=random_shuffle)

    event = {
        "event": event_index,
        "reason": regeneration_reason,
        "remaining_rounds": remaining_rounds,
        "runtime_weights": runtime_weights,
        "final_weights": final_weights,
        "budget": budget,
        "schedule": list(schedule),
        **pool_trace,
        "filtered_candidate_pool": [
            _serialize_candidate(candidate) for candidate in pool_candidates
        ],
    }

    return pool_candidates, schedule, event


def _run_round(
    pool_candidates: list[RefinementCandidate],
    current_dim: str,
    asked_bundle_keys: set[str],
    asked_attribute_keys: set[str],
    user_proxy: UserProxy,
    round_index: int,
    schedule_index: int,
) -> tuple[
    list[RefinementCandidate],
    dict[str, Any],
    str,
    bool | None,
    RefinementCandidate,
]:
    """Run one scheduled clarification round and update the candidate pool."""
    available_candidates = _available_candidates(
        pool_candidates,
        current_dim,
        asked_bundle_keys,
        asked_attribute_keys,
    )
    chosen_candidate = _choose_candidate(available_candidates)
    chosen_key = _candidate_key(chosen_candidate)

    if current_dim == "attribute":
        asked_attribute_keys.add(chosen_key)
    else:
        asked_bundle_keys.add(chosen_key)

    question = _generate_question_from_candidate(chosen_candidate)
    answer_list = user_proxy(question)
    observed_answer = answer_list[0] if answer_list else None

    pool_size_before = len(pool_candidates)
    pool_candidates = _prune_candidates(
        pool_candidates,
        chosen_candidate,
        observed_answer,
    )
    pool_size_after = len(pool_candidates)

    round_trace = {
        "round": round_index,
        "dimension": current_dim,
        "schedule_index": schedule_index,
        "chosen_candidate": _serialize_candidate(chosen_candidate),
        "question": question,
        "observed_answer": observed_answer,
        "pool_size_before": pool_size_before,
        "pool_size_after": pool_size_after,
        "remaining_actions_in_dimension": sum(
            1 for candidate in pool_candidates if candidate.dimension == current_dim
        ),
    }

    return pool_candidates, round_trace, question, observed_answer, chosen_candidate


def build(
    max_questions: int,
    config: Dict[str, Any] = None,
    ratios: tuple[int, int, int] = (3, 2, 1),
    skip_prior_weighting: bool = False,
    dar_shuffle: bool = False,
    fix_round: bool = False,
    **kwargs,
) -> Callable:
    """
    Build the dimension_aware_refinement method runner.

    Args:
        max_questions: Total clarification rounds available.
        config: Experiment config dict with optional role keys.
        ratios: Prior (resource, topology, attribute) weighting.
        skip_prior_weighting: Whether to use raw pool counts directly.

    Returns:
        run(prompt, cfg) -> {"clarified_intent": str, "spec": dict, "traces": {...}}
    """
    config = config or {}

    def run(prompt: str, cfg: str = "") -> dict:
        # Shared generators and the proxy stay live across the full interaction.
        spec_gen = SpecGenerator(config=config, awscc=is_awscc(prompt))
        proxy_llm = make_llm(config, "proxy", stateful=True)
        user_proxy = UserProxy(llm=proxy_llm, cfg=cfg)

        # Carry Q/A history forward because regeneration is driven by it.
        questions: list[str] = []
        answers: list[bool | None] = []
        round_traces: list[dict[str, Any]] = []
        pool_events: list[dict[str, Any]] = []
        asked_history: list[tuple[RefinementCandidate, bool | None]] = []
        asked_bundle_keys: set[str] = set()
        asked_attribute_keys: set[str] = set()

        regeneration_reason = "initial_generation"
        schedule: list[str] = []
        schedule_index = 0
        pool_candidates: list[RefinementCandidate] = []
        regeneration_attempted = False

        # Each iteration can rebuild the remaining plan and then execute one round.
        while len(questions) < max_questions:
            remaining_rounds = max_questions - len(questions)

            # Build the initial pool, and rebuild it whenever the schedule is exhausted.
            if schedule_index >= len(schedule):
                if remaining_rounds <= 0:
                    break

                pool_candidates, schedule, pool_event = _refresh_pool_and_schedule(
                    spec_gen,
                    prompt,
                    questions,
                    answers,
                    asked_history,
                    asked_bundle_keys,
                    asked_attribute_keys,
                    remaining_rounds,
                    ratios,
                    skip_prior_weighting,
                    regeneration_reason,
                    len(pool_events) + 1,
                    random_shuffle=dar_shuffle,
                )
                schedule_index = 0
                pool_events.append(pool_event)

            # Stop if refresh still produced no schedulable rounds.
            if not schedule:
                break

            current_dim = schedule[schedule_index]

            # Refresh if the pool is empty or this dimension has no available actions.
            reason = _regeneration_reason(
                pool_candidates,
                current_dim,
                asked_bundle_keys,
                asked_attribute_keys,
            )

            if reason is not None:
                if regeneration_attempted:
                    # Stop if one refresh still cannot support the current round.
                    break

                regeneration_reason = reason
                schedule = []
                schedule_index = 0
                regeneration_attempted = True
                continue

            regeneration_attempted = False
            (
                pool_candidates,
                round_trace,
                question,
                observed_answer,
                chosen_candidate,
            ) = _run_round(
                pool_candidates,
                current_dim,
                asked_bundle_keys,
                asked_attribute_keys,
                user_proxy,
                len(questions) + 1,
                schedule_index,
            )

            questions.append(question)
            answers.append(observed_answer)
            round_traces.append(round_trace)
            asked_history.append((chosen_candidate, observed_answer))
            schedule_index += 1

        # Fill remaining budget with random questions when fix_round is enabled.
        remaining = max_questions - len(questions)
        if fix_round and remaining > 0:
            intermediate_intent = build_clarified_intent(prompt, questions, answers)
            random_q_llm = make_llm(config, "clarifier",
                                    system_prompt=QUESTION_GENERATOR_SYSTEM_PROMPT,
                                    stateful=True)
            random_questions = generate_questions(random_q_llm, intermediate_intent, remaining)
            for rq in random_questions:
                answer_list = user_proxy(rq)
                observed_answer = answer_list[0] if answer_list else None
                questions.append(rq)
                answers.append(observed_answer)

        # The final spec is generated from the original prompt plus the Q/A history.
        clarified_intent = build_clarified_intent(prompt, questions, answers)
        final_spec = _parse_spec(
            spec_gen.generate_spec(prompt, feedback=clarified_intent)
        )

        return {
            "clarified_intent": clarified_intent,
            "spec": final_spec,
            "traces": {
                "spec_generator_llm": {
                    "messages": spec_gen.llm.get_memory(),
                    "usage": spec_gen.llm.get_usage(),
                    "config": spec_gen.llm.get_config(),
                },
                "proxy_llm": {
                    "messages": proxy_llm.get_memory(),
                    "usage": proxy_llm.get_usage(),
                    "config": proxy_llm.get_config(),
                },
                "dimension_aware_refinement_settings": {
                    "ratios": {
                        "resource": ratios[0],
                        "topology": ratios[1],
                        "attribute": ratios[2],
                    },
                    "skip_prior_weighting": skip_prior_weighting,
                    "max_questions": max_questions,
                },
                "dimension_aware_refinement_trace": {
                    "messages": round_traces,
                    "usage": {},
                    "config": {
                        "max_questions": max_questions,
                    },
                },
                "pool_trace": {
                    "messages": pool_events,
                    "usage": {},
                    "config": {
                        "max_questions": max_questions,
                    },
                },
            },
        }

    return run
