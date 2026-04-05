"""
Method registry — single dispatch point for clarification methods.

Each method module exposes a `build(**kwargs) -> Callable` that returns a
`run(prompt, cfg) -> dict` closure.
"""

from typing import Any, Callable, Dict

from src.methods import (
    best_of_n,
    dimension_aware_refinement,
    direct,
    direct_random_q,
    self_consistency,
)

METHODS: dict[str, Callable] = {
    "direct": direct.build,
    "direct_random_q": direct_random_q.build,
    "best_of_n": best_of_n.build,
    "self_consistency": self_consistency.build,
    "dimension_aware_refinement": dimension_aware_refinement.build,
}


def build_method(name: str, config: Dict[str, Any] = None, **kwargs) -> Callable:
    """Build and return a method runner by name.

    Args:
        name:   Method name (must be in METHODS).
        config: Experiment config dict passed to the method builder.
        **kwargs: Extra keyword args forwarded to the method builder.
    """
    if name not in METHODS:
        available = ", ".join(METHODS)
        raise ValueError(f"Unknown method: {name!r}. Available: {available}")

    print(f"Building method {name} with kwargs: {kwargs}")

    return METHODS[name](config=config, **kwargs)
