"""
Experiment configuration: per-role LLM settings.

Config is a JSON file with optional keys for each role (clarifier, proxy, generator).
Omitted roles or fields fall back to LLM defaults (env vars for credentials, class
defaults for model params). See configs/example.json for reference.
"""

import json
from pathlib import Path
from typing import Dict, Any, Optional

from src.utils.llm import LLM

# Fields from config that map directly to LLM.__init__ kwargs
_LLM_FIELDS = {"model", "max_tokens", "temperature", "api_key", "api_version", "azure_endpoint"}


def load_config(path: Optional[str] = None) -> Dict[str, Any]:
    """Load config from a JSON file. Returns empty dict if path is None."""
    if path is None:
        return {}
    return json.loads(Path(path).read_text())


def make_llm(config: Dict[str, Any], role: str = "", **overrides) -> LLM:
    """
    Create an LLM instance from config for a given role.

    Args:
        config:    Full config dict (with optional role keys).
        role:      One of "clarifier", "proxy", "generator".
        overrides: Extra kwargs passed directly to LLM (e.g. system_prompt, stateful).
                   These take priority over config values.

    Returns:
        Configured LLM instance.
    """
    if role is not None and role != "":
        role_cfg = config.get(role, {})
        # if role_cfg is {} then the cfg might be flat, so we use the config directly
        if not role_cfg:
            role_cfg = config
    else:
        role_cfg = config
    kwargs = {k: v for k, v in role_cfg.items() if k in _LLM_FIELDS}
    kwargs.update(overrides)
    return LLM(**kwargs)
