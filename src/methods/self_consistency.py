"""
self_consistency method: generate many candidate questions, cluster by semantic
similarity, and pick the consensus (largest-cluster centroid) question each round.

For each round:
1. Generate n_candidates diverse yes/no questions (conditioned on prior Q&A)
2. Embed questions with sentence-transformers (all-MiniLM-L6-v2)
3. K-Means cluster embeddings
4. Pick the question closest to the centroid of the largest cluster
5. Ask the UserProxy that single question
6. Accumulate Q&A, repeat for max_questions rounds

Produces a clarified intent string from the full Q&A exchange.
"""

from collections import Counter
from typing import Callable, Dict, Any

import numpy as np

from src.config import make_llm
from src.user_proxy import UserProxy
from src.utils.llm import LLM
from src.methods.direct_random_q import (
    QUESTION_GENERATOR_SYSTEM_PROMPT,
    build_clarified_intent,
)


# ---------------------------------------------------------------------------
# Lazy-loaded embedding model (singleton)
# ---------------------------------------------------------------------------
_model = None


def _get_model():
    global _model
    if _model is None:
        from sentence_transformers import SentenceTransformer
        _model = SentenceTransformer("all-MiniLM-L6-v2")
    return _model


# ---------------------------------------------------------------------------
# Core helpers
# ---------------------------------------------------------------------------

def generate_candidate_questions(
    llm: LLM,
    prompt: str,
    prior_questions: list[str],
    prior_answers: list[bool | None],
    n: int = 20,
) -> list[str]:
    """Generate n candidate clarification questions, conditioned on prior Q&A."""
    parts = [f"Infrastructure request: {prompt}"]
    if prior_questions:
        parts.append("Previously asked:")
        for q, a in zip(prior_questions, prior_answers):
            a_str = "Yes" if a is True else ("No" if a is False else "Unknown")
            parts.append(f"  Q: {q}\n  A: {a_str}")
    parts.append(
        f"\nGenerate exactly {n} NEW yes/no questions to clarify ambiguities in "
        "this request. Do not repeat or rephrase any question already asked."
    )
    response = llm("\n".join(parts))
    candidates = [line.strip() for line in response.strip().splitlines() if line.strip()]
    return candidates[:n]


def embed_questions(questions: list[str]) -> np.ndarray:
    """Embed questions using sentence-transformers."""
    return _get_model().encode(questions)


def select_consensus_question(questions: list[str], embeddings: np.ndarray) -> str:
    """Cluster embeddings with K-Means, return the question closest to the
    centroid of the largest cluster."""
    from sklearn.cluster import KMeans

    k = max(2, len(questions) // 4)
    k = min(k, len(questions))  # can't have more clusters than samples
    kmeans = KMeans(n_clusters=k, n_init=10, random_state=42).fit(embeddings)

    # Find largest cluster
    labels = kmeans.labels_
    largest = Counter(labels).most_common(1)[0][0]

    # Pick closest to centroid within that cluster
    centroid = kmeans.cluster_centers_[largest]
    mask = labels == largest
    indices = np.where(mask)[0]
    dists = np.linalg.norm(embeddings[indices] - centroid, axis=1)
    best_idx = indices[np.argmin(dists)]
    return questions[best_idx]


# ---------------------------------------------------------------------------
# Builder
# ---------------------------------------------------------------------------

def build(
    max_questions: int,
    n_candidates: int = 20,
    config: Dict[str, Any] = None,
) -> Callable:
    """
    Build the self_consistency method runner.

    Args:
        max_questions:  Total rounds (one consensus question per round).
        n_candidates:   Candidates generated per round for clustering.
        config:         Experiment config dict with optional role keys.

    Returns:
        run(prompt, cfg) -> {"clarified_intent": str, "traces": {name: {...}}}
    """
    config = config or {}

    def run(prompt: str, cfg: str = "") -> dict:
        clarifier_llm = make_llm(
            config, "clarifier",
            system_prompt=QUESTION_GENERATOR_SYSTEM_PROMPT, stateful=True,
        )
        proxy_llm = make_llm(config, "proxy", stateful=True)
        user_proxy = UserProxy(llm=proxy_llm, cfg=cfg)

        questions: list[str] = []
        answers: list[bool | None] = []

        for i in range(max_questions):
            # 1. Generate n candidates
            candidates = generate_candidate_questions(
                clarifier_llm, prompt, questions, answers, n_candidates,
            )
            print(f"[Round {i+1}] Generated {len(candidates)} candidates")

            if not candidates:
                print("  → No candidates generated, stopping early.")
                break

            # 2-4. Embed, cluster, select consensus
            if len(candidates) == 1:
                best_q = candidates[0]
            else:
                embs = embed_questions(candidates)
                best_q = select_consensus_question(candidates, embs)
            print(f"  → Consensus: {best_q}")

            # 5. Ask user proxy
            answer_list = user_proxy(best_q)
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
                "proxy_llm": {
                    "messages": proxy_llm.get_memory(),
                    "usage": proxy_llm.get_usage(),
                    "config": proxy_llm.get_config(),
                },
            },
        }

    return run
