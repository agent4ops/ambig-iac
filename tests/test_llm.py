"""
Simple test for LLM class: one LLM call.

In root directory, run:
uv run -m tests.test_llm
"""

import sys
from pathlib import Path

from src.utils.llm import LLM


def test_llm_one_call():
    """Make a single LLM call and check we get a non-empty response."""
    print("Testing LLM API")
    llm = LLM(system_prompt="You are a helpful assistant.", model="gpt-4o-mini", stateful=True)
    msg = "User: my name is Tom, hello"
    reply = llm(msg)
    print(f"User: {msg}")
    print(f"LLM: {reply}")


if __name__ == "__main__":
    test_llm_one_call()

