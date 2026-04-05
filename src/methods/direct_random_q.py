"""
direct_random_q method: LLM generates random yes/no questions, UserProxy answers them.

Produces a clarified intent string from the Q&A exchange.
Composable: `prompt` can be a raw task prompt or a previously enriched intent.
"""

from typing import Callable, Dict, Any

from src.config import make_llm
from src.user_proxy import UserProxy
from src.utils.llm import LLM


QUESTION_GENERATOR_SYSTEM_PROMPT = """You are an AWS infrastructure expert reviewing an ambiguous infrastructure request.
Your job is to generate yes/no questions that clarify the exact infrastructure the user wants.
Rules:
- Every question MUST be answerable with only "yes" or "no". No open-ended questions.
- Focus on aspects that are NOT explicitly stated in the prompt but would meaningfully affect the Terraform code.
- Do NOT ask questions whose answers require a specific value (e.g. "What region?") — rephrase as yes/no (e.g. "Should this be deployed in us-east-1?").
Output ONLY the questions, one per line, with no numbering or preamble."""


def generate_questions(llm: LLM, task_prompt: str, n: int) -> list[str]:
    """Use an LLM to generate n yes/no clarification questions for the given task prompt."""
    user_message = (
        f"Infrastructure request: {task_prompt}\n\n"
        f"Generate exactly {n} yes/no questions to clarify ambiguities in this request."
    )
    response = llm(user_message)
    questions = [line.strip() for line in response.strip().splitlines() if line.strip()]
    return questions[:n]


def build_clarified_intent(task_prompt: str, questions: list[str], answers: list[bool | None]) -> str:
    """Combine the original task prompt with the Q&A pairs into a clarified intent string."""
    parts = [f"Task: {task_prompt}"]
    for q, a in zip(questions, answers):
        if a is True:
            answer_str = "Yes"
        elif a is False:
            answer_str = "No"
        else:
            answer_str = "Unknown"
        parts.append(f"Q: {q}\nA: {answer_str}")
    return "\n\n".join(parts)


def build(max_questions: int, config: Dict[str, Any] = None) -> Callable:
    """
    Build the direct_random_q method runner.

    Args:
        max_questions: Number of clarification questions to generate.
        config:        Experiment config dict with optional role keys
                       ("clarifier", "proxy", "generator").

    Returns:
        run(prompt, cfg) -> {"clarified_intent": str, "traces": {name: {...}}}
    """
    config = config or {}

    def run(prompt: str, cfg: str = "") -> dict:
        """
        Args:
            prompt: task prompt OR already-enriched intent (for composition)
            cfg: reference main.tf content for UserProxy
        Returns:
            {"clarified_intent": str, "traces": {"question_llm": {...}, "proxy_llm": {...}}}
        """
        # Generate clarification questions
        question_llm = make_llm(config, "clarifier",
                                system_prompt=QUESTION_GENERATOR_SYSTEM_PROMPT, stateful=True)
        questions = generate_questions(question_llm, prompt, max_questions)
        print(f"[Questions] Generated {len(questions)} questions:")
        for i, q in enumerate(questions, 1):
            print(f"  {i}. {q}")
        print()

        # Ask UserProxy
        proxy_llm = make_llm(config, "proxy", stateful=True)
        user_proxy = UserProxy(llm=proxy_llm, cfg=cfg)
        request = "\n".join(questions)
        answers = user_proxy(request)
        print(f"[Answers] {answers}\n")

        # Build clarified intent
        clarified_intent = build_clarified_intent(prompt, questions, answers)

        return {
            "clarified_intent": clarified_intent,
            "traces": {
                "question_llm": {"messages": question_llm.get_memory(), "usage": question_llm.get_usage(), "config": question_llm.get_config()},
                "proxy_llm": {"messages": proxy_llm.get_memory(), "usage": proxy_llm.get_usage(), "config": proxy_llm.get_config()},
            },
        }

    return run
