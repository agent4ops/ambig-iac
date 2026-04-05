"""
direct method: no clarification questions, pass the prompt through as-is.
"""

from typing import Callable, Dict, Any


def build(config: Dict[str, Any] = None, **kwargs) -> Callable:
    def run(prompt: str, cfg: str = "") -> dict:
        return {
            "clarified_intent": prompt,
            "traces": {},
        }
    return run
