"""
Shared utilities for weighted methods (weighted_best_of_n, weighted_self_consistency).

Provides:
- compute_runtime_question_weights: probe the LLM's natural dimension distribution
- compute_runtime_spec_weights: estimate ambiguity from spec edit actions
- resolve_final_weights: optionally combine runtime weights with a prior
- compute_final_weights: combine runtime weights with a prior
- compute_question_budget: allocate a question budget across dimensions
- generate_typed_candidates: generate n questions of a specific dimension type
"""

import json
import re
from math import ceil
from typing import Dict

from src.edit_actions import EditAction, parse_edits
from src.methods.direct_random_q import build_clarified_intent
from src.utils.llm import LLM
from src.spec_generator import SpecGenerator
from src.spec_types import Spec


WEIGHTED_QUESTION_GENERATOR_SYSTEM_PROMPT = """\
You are an AWS infrastructure expert reviewing an ambiguous infrastructure request.
Your job is to generate yes/no questions that clarify the exact infrastructure the user wants.

Questions fall into three categories:

**Resource questions** — whether a specific AWS resource type is needed.
Examples:
- "Should an S3 bucket be created for storing logs?"
- "Is a NAT Gateway required for outbound internet access from private subnets?"
- ...

**Topology questions** — relationships, dependencies, and references between resources (e.g. name/ID references in IaC).
Examples:
- "Should the Lambda function be connected to the VPC?"
- "Should the RDS instance be placed in a private subnet behind the ALB?"
- ...

**Attribute questions** — specific configuration values or settings for resources.
Examples:
- "Should the EC2 instance type be t3.micro?"
- "Should encryption at rest be enabled for the S3 bucket?"
- ...

Rules:
- NEVER ask about something already stated or clearly implied by the prompt. If the prompt says "create an S3 bucket", do NOT ask "Should an S3 bucket be created?" — that is already answered. Only ask about genuinely ambiguous or unspecified aspects.
- Every question MUST be answerable with only "yes" or "no". No open-ended questions.
- Focus on aspects that are NOT explicitly stated in the prompt but would meaningfully affect the Terraform code.
- Do NOT ask questions whose answers require a specific value (e.g. "What region?") — rephrase as yes/no (e.g. "Should this be deployed in us-east-1?").
- Output ONLY the questions, one per line, with no numbering or preamble."""

DIMENSION_PROBE_SYSTEM_PROMPT = """\
You are an AWS infrastructure expert reviewing an ambiguous infrastructure request.
Your job is to generate yes/no clarification questions and label each with its dimension.

Dimensions:
- [resource] — whether a specific AWS resource type is needed
- [topology] — relationships, dependencies, and references between resources
- [attribute] — specific configuration values or settings for resources

Rules:
- Every question MUST be answerable with only "yes" or "no".
- Prefix each question with its dimension label in square brackets.
- Focus on aspects NOT explicitly stated in the prompt.
- Output ONLY the labeled questions, one per line, with no numbering or preamble.

Example output:
[resource] Should an S3 bucket be created for storing logs?
[topology] Should the Lambda function be connected to the VPC?
[attribute] Should encryption at rest be enabled for the S3 bucket?"""


TYPED_QUESTION_GEN_SYSTEM_PROMPT = WEIGHTED_QUESTION_GENERATOR_SYSTEM_PROMPT


DIMENSION_LABELS = ("resource", "topology", "attribute")


def compute_runtime_question_weights(
    llm: LLM, task_prompt: str, n_sample: int = 10,
) -> Dict[str, int]:
    """Probe the LLM to find the natural dimension distribution for a task.

    Generates ``n_sample`` freely-labeled questions, counts how many fall into
    each dimension, and returns those counts as runtime weights.
    """
    user_message = (
        f"Infrastructure request: {task_prompt}\n\n"
        f"Generate exactly {n_sample} yes/no clarification questions for this request. "
        "Label each question with its dimension ([resource], [topology], or [attribute])."
    )
    response = llm(user_message)

    counts: Dict[str, int] = {"resource": 0, "topology": 0, "attribute": 0}
    label_re = re.compile(r"^\[(\w+)\]")
    for line in response.strip().splitlines():
        line = line.strip()
        if not line:
            continue
        m = label_re.match(line)
        if m:
            dim = m.group(1).lower()
            if dim in counts:
                counts[dim] += 1

    # Fallback: if parsing failed entirely, use uniform weights
    if sum(counts.values()) == 0:
        counts = {"resource": 1, "topology": 1, "attribute": 1}

    return counts


def _parse_spec(raw_spec: str) -> Spec:
    """Parse a raw spec string into a three-key spec dict."""
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

    parsed: Spec = {
        "resources": resources,
        "topology": topology,
        "attributes": attributes,
    }

    return parsed


def _build_added_feedback(
    prompt: str,
    questions: list[str] | None,
    answers: list[bool | None] | None,
) -> str:
    """Build added feedback from optional clarification Q/A."""
    normalized_questions = questions or []
    normalized_answers = answers or []

    if not normalized_questions and not normalized_answers:
        return ""

    return build_clarified_intent(prompt, normalized_questions, normalized_answers)


def _count_axes(actions: list[EditAction]) -> dict[str, int]:
    """Count parsed edit actions by returned axis name."""
    counts = {
        "resource": 0,
        "topology": 0,
        "attribute": 0,
    }

    for action in actions:
        if action.field == "resource":
            counts["resource"] += 1
        elif action.field == "topology":
            counts["topology"] += 1
        elif action.field == "attribute":
            counts["attribute"] += 1

    return counts


def compute_runtime_spec_weights(
    llm: LLM,
    prompt: str,
    num_specs: int = 1,
    questions: list[str] | None = None,
    answers: list[bool | None] | None = None,
) -> dict[str, float]:
    """Estimate runtime axis weights from generated specs and interpretation edits."""
    if num_specs < 1:
        raise ValueError("num_specs must be at least 1")

    spec_generator = SpecGenerator(llm=llm)
    added_feedback = _build_added_feedback(prompt, questions, answers)
    counts = {
        "resource": 0,
        "topology": 0,
        "attribute": 0,
    }

    for _ in range(num_specs):
        raw_spec = spec_generator.generate_spec(prompt, feedback=added_feedback)
        spec = _parse_spec(raw_spec)
        raw_actions = spec_generator.generate_interpretation_edits(
            prompt,
            spec,
            clarified_intent=added_feedback,
        )
        parsed_actions = parse_edits(raw_actions)
        axis_counts = _count_axes(parsed_actions)

        for axis, value in axis_counts.items():
            counts[axis] += value

    total_actions = sum(counts.values())

    if total_actions == 0:
        raise ValueError("No parseable edit actions were generated")

    return {
        axis: value / total_actions
        for axis, value in counts.items()
    }


def compute_final_weights(
    runtime_weights: Dict[str, int],
    prior: tuple[int, int, int] = (3, 2, 1),
) -> Dict[str, int]:
    """Multiply runtime counts by prior weights to get final (unnormalized) weights."""
    dims = ("resource", "topology", "attribute")
    return {
        dim: runtime_weights.get(dim, 0) * p
        for dim, p in zip(dims, prior)
    }


def resolve_final_weights(
    runtime_weight_source: str,
    runtime_weights: Dict[str, int | float],
    prior: tuple[int, int, int] = (3, 2, 1),
    skip_prior_weighting: bool = False,
) -> Dict[str, int | float]:
    """Resolve final weights from runtime weights and the configured prior."""
    if runtime_weight_source == "fixed" or skip_prior_weighting:
        return dict(runtime_weights)

    return compute_final_weights(runtime_weights, prior=prior)


def compute_question_budget(
    max_questions: int, weights: Dict[str, int],
) -> Dict[str, int]:
    """Allocate a question budget proportionally to the given weights.

    Same logic as ``direct_weighted_q.compute_question_counts`` but accepts
    an arbitrary weights dict.
    """
    total_weight = sum(weights.values())
    if total_weight == 0:
        # Degenerate case: uniform fallback
        total_weight = 3
        weights = {"resource": 1, "topology": 1, "attribute": 1}

    dims = ["resource", "topology", "attribute"]
    counts: Dict[str, int] = {}
    allocated = 0
    for dim in dims[:-1]:
        c = ceil(max_questions * weights[dim] / total_weight)
        c = min(c, max_questions - allocated)
        counts[dim] = c
        allocated += c
    counts[dims[-1]] = max(0, max_questions - allocated)
    return counts


def generate_typed_candidates(
    llm: LLM,
    task_prompt: str,
    question_type: str,
    n: int,
    prior_questions: list[str],
    prior_answers: list[bool | None],
) -> list[str]:
    """Generate ``n`` candidate questions of a specific dimension type.

    Args:
        llm: LLM instance (should use TYPED_QUESTION_GEN_SYSTEM_PROMPT).
        task_prompt: The original infrastructure request.
        question_type: One of "resource", "topology", "attribute".
        n: Number of candidates to generate.
        prior_questions: Questions already asked.
        prior_answers: Answers already received.
    """
    type_desc = {
        "resource": "resource questions (whether a specific AWS resource type is needed)",
        "topology": "topology questions (relationships/dependencies/references between resources)",
        "attribute": "attribute questions (specific configuration values/settings for resources)",
    }

    parts = [f"Infrastructure request: {task_prompt}"]
    if prior_questions:
        parts.append("Questions already asked and answered:")
        for q, a in zip(prior_questions, prior_answers):
            a_str = "Yes" if a is True else ("No" if a is False else "Unknown")
            parts.append(f"  Q: {q}\n  A: {a_str}")
    parts.append(
        f"\nGenerate exactly {n} NEW {type_desc[question_type]}. "
        "Do not repeat or rephrase any question already asked."
    )
    response = llm("\n".join(parts))
    candidates = [line.strip() for line in response.strip().splitlines() if line.strip()]
    return candidates[:n]
