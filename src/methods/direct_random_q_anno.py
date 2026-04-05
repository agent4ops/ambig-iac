"""
direct_random_q_anno method: like direct_random_q, but each question is prefixed
with a dimension label such as [resource], [topology], [attribute], or a
combination like [resource,topology].

Produces a clarified intent string from the Q&A exchange.
"""

from typing import Callable, Dict, Any

from src.config import make_llm
from src.methods.direct_random_q import build_clarified_intent
from src.user_proxy import UserProxy
from src.utils.llm import LLM


QUESTION_GENERATOR_SYSTEM_PROMPT = """You are an AWS infrastructure expert reviewing an ambiguous infrastructure request.
Your job is to generate yes/no questions that clarify the exact infrastructure the user wants.

Rules:
- Every question MUST be answerable with only "yes" or "no". No open-ended questions.
- Focus on aspects that are NOT explicitly stated in the prompt but would meaningfully affect the Terraform code.
- Do NOT ask questions whose answers require a specific value (e.g. "What region?") — rephrase as yes/no (e.g. "Should this be deployed in us-east-1?").
- Each question MUST start with a dimension label in square brackets indicating what aspect of the infrastructure it clarifies:
  [resource]   — whether a resource should exist (e.g. "[resource] Should there be a load balancer?")
  [topology]   — how resources relate or depend on each other (e.g. "[topology] Should the subnet be in the VPC?")
  [attribute]  — configuration values of a resource (e.g. "[attribute] Should the instance type be t3.micro?")
  You may combine labels for questions that span multiple dimensions, e.g. "[resource,attribute]" or "[resource,topology]".

Output ONLY the questions, one per line, with no numbering or preamble."""


def generate_questions(llm: LLM, task_prompt: str, n: int) -> list[str]:
    """Use an LLM to generate n dimension-annotated yes/no clarification questions."""
    user_message = (
        f"Infrastructure request: {task_prompt}\n\n"
        f"Generate exactly {n} yes/no questions to clarify ambiguities in this request. "
        f"Each question must start with a dimension label like [resource], [topology], "
        f"[attribute], or a combination like [resource,attribute], etc."
    )
    response = llm(user_message)
    questions = [line.strip() for line in response.strip().splitlines() if line.strip()]
    return questions[:n]


def build(max_questions: int, config: Dict[str, Any] = None) -> Callable:
    """
    Build the direct_random_q_anno method runner.

    Args:
        max_questions: Number of clarification questions to generate.
        config:        Experiment config dict with optional role keys
                       ("clarifier", "proxy", "generator").

    Returns:
        run(prompt, cfg) -> {"clarified_intent": str, "traces": {name: {...}}}
    """
    config = config or {}

    def run(prompt: str, cfg: str = "") -> dict:
        # Generate annotated clarification questions
        question_llm = make_llm(config, "clarifier",
                                system_prompt=QUESTION_GENERATOR_SYSTEM_PROMPT, stateful=True)
        questions = generate_questions(question_llm, prompt, max_questions)
        print(f"[Questions] Generated {len(questions)} annotated questions:")
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
