"""
best_of_n method: iteratively generate, rank, and ask clarification questions.

For each question slot:
1. Generate n candidate yes/no questions (conditioned on prior Q&A)
2. Rank candidates by expected information gain, pick the best
3. Ask the UserProxy, get yes/no answer
4. Accumulate Q&A for next round

Produces a clarified intent string from the full Q&A exchange.
"""

from typing import Callable, Dict, Any

from src.config import make_llm
from src.user_proxy import UserProxy
from src.utils.llm import LLM
from src.methods.direct_random_q import build_clarified_intent


QUESTION_GEN_SYSTEM_PROMPT = """You are an AWS infrastructure expert reviewing an ambiguous infrastructure request.
Your job is to generate candidate yes/no clarification questions.
Rules:
- Every question MUST be answerable with only "yes" or "no". No open-ended questions.
- Focus on aspects that are NOT explicitly stated in the prompt but would meaningfully affect the Terraform code.
- Do NOT ask questions whose answers require a specific value (e.g. "What region?") — rephrase as yes/no (e.g. "Should this be deployed in us-east-1?").
- Do NOT repeat or rephrase questions that have already been asked.
- Output ONLY the questions, one per line, with no numbering or preamble."""

RANKER_SYSTEM_PROMPT = """You are an expert at evaluating clarification questions for ambiguous infrastructure requests.
Given a task prompt, prior Q&A context, and a list of candidate questions, pick the single question whose answer would most reduce ambiguity about the required Terraform configuration.
Criteria:
- Prefer questions that address the MOST uncertain or impactful aspects of the infrastructure.
- Prefer questions that are INDEPENDENT of what has already been answered.
- Output ONLY the text of the best question, exactly as it appears in the candidate list. No explanation."""


def generate_candidates(
    llm: LLM,
    prompt: str,
    prior_questions: list[str],
    prior_answers: list[bool | None],
    n: int,
) -> list[str]:
    """Generate n candidate clarification questions, conditioned on prior Q&A."""
    parts = [f"Infrastructure request: {prompt}"]
    if prior_questions:
        parts.append("Questions already asked and answered:")
        for q, a in zip(prior_questions, prior_answers):
            a_str = "Yes" if a is True else ("No" if a is False else "Unknown")
            parts.append(f"  Q: {q}\n  A: {a_str}")
    parts.append(
        f"\nGenerate exactly {n} NEW yes/no questions to further clarify this request. "
        "Do not repeat or rephrase any question already asked."
    )
    response = llm("\n".join(parts))
    candidates = [line.strip() for line in response.strip().splitlines() if line.strip()]
    return candidates[:n]


def rank_candidates(
    llm: LLM,
    prompt: str,
    prior_questions: list[str],
    prior_answers: list[bool | None],
    candidates: list[str],
) -> str:
    """Rank candidate questions by information gain, return the best one."""
    if len(candidates) == 1:
        return candidates[0]

    parts = [f"Infrastructure request: {prompt}"]
    if prior_questions:
        parts.append("Prior Q&A:")
        for q, a in zip(prior_questions, prior_answers):
            a_str = "Yes" if a is True else ("No" if a is False else "Unknown")
            parts.append(f"  Q: {q}\n  A: {a_str}")
    parts.append("\nCandidate questions:")
    for i, c in enumerate(candidates, 1):
        parts.append(f"  {i}. {c}")
    parts.append(
        "\nWhich single question would most reduce ambiguity about the required "
        "Terraform configuration? Output ONLY the text of that question."
    )
    response = llm("\n".join(parts)).strip()

    # Try to match response to a candidate (fuzzy: strip punctuation/whitespace)
    for c in candidates:
        if c.strip().lower() in response.lower() or response.lower() in c.strip().lower():
            return c
    # Fallback: return the response as-is (ranker may have slightly rephrased)
    return response


def build(max_questions: int, n_candidates: int = 3, config: Dict[str, Any] = None) -> Callable:
    """
    Build the best_of_n method runner.

    Args:
        max_questions:  Total questions to ask the user.
        n_candidates:   Candidates generated per round for ranking.
        config:         Experiment config dict with optional role keys.

    Returns:
        run(prompt, cfg) -> {"clarified_intent": str, "traces": {name: {...}}}
    """
    config = config or {}

    def run(prompt: str, cfg: str = "") -> dict:
        clarifier_llm = make_llm(
            config, "clarifier",
            system_prompt=QUESTION_GEN_SYSTEM_PROMPT, stateful=False,
        )
        ranker_llm = make_llm(
            config, "ranker",
            system_prompt=RANKER_SYSTEM_PROMPT, stateful=False,
        )
        proxy_llm = make_llm(config, "proxy", stateful=True)
        user_proxy = UserProxy(llm=proxy_llm, cfg=cfg)

        questions: list[str] = []
        answers: list[bool | None] = []

        for i in range(max_questions):
            # 1. Generate n candidates
            candidates = generate_candidates(
                clarifier_llm, prompt, questions, answers, n_candidates,
            )
            print(f"[Round {i+1}] Generated {len(candidates)} candidates:")
            for j, c in enumerate(candidates, 1):
                print(f"    {j}. {c}")

            # 2. Rank and pick top
            best_q = rank_candidates(ranker_llm, prompt, questions, answers, candidates)
            print(f"  → Best: {best_q}")

            # 3. Ask user proxy
            answer_list = user_proxy(best_q)  # returns [bool]
            answer = answer_list[0] if answer_list else None
            print(f"  → Answer: {'Yes' if answer is True else ('No' if answer is False else 'Unknown')}\n")

            questions.append(best_q)
            answers.append(answer)

        clarified_intent = build_clarified_intent(prompt, questions, answers)

        return {
            "clarified_intent": clarified_intent,
            "traces": {
                "clarifier_llm": {
                    "messages": clarifier_llm.get_memory(),
                    "usage": clarifier_llm.get_usage(),
                    "config": clarifier_llm.get_config(),
                },
                "ranker_llm": {
                    "messages": ranker_llm.get_memory(),
                    "usage": ranker_llm.get_usage(),
                    "config": ranker_llm.get_config(),
                },
                "proxy_llm": {
                    "messages": proxy_llm.get_memory(),
                    "usage": proxy_llm.get_usage(),
                    "config": proxy_llm.get_config(),
                },
            },
        }

    return run
