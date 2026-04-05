# Ambig-IaC: Multi-level Disambiguation for Interactive Cloud Infrastructure-as-Code Synthesis

[Project Page](https://zyang37.github.io/ambig-iac.github.io/)

Research framework for evaluating LLM-generated Terraform (IaC) code. Measures how well LLMs handle ambiguous or incomplete infrastructure specifications through clarification-based methods and spec-level evaluation.

## Setup

```bash
# Install dependencies
uv sync
```

Requires:
- Python 3.13+
- Azure OpenAI credentials via environment variables (`AZURE_OPENAI_API_KEY`, `AZURE_OPENAI_ENDPOINT`, `OPENAI_API_VERSION`)

## Pipeline Overview

```
Dataset task (prompt.txt + main.tf)
  → Clarification method (direct / direct_random_q / best_of_n / self_consistency / dimension_aware_refinement)
  → Spec generation (LLM produces resources / topology / attributes JSON)
  → Evaluation (compare generated spec against ground-truth derived from plan.json)
```

## Clarification Methods (`main.py`)

Run a clarification method to produce a clarified intent and generate a spec:

```bash
uv run main.py --dataset ambig-iac --method <method> --max_questions 5 --out_dir results/<method>/
```

| Method | Description |
|--------|-------------|
| `direct` | No clarification — passes prompt through as-is |
| `direct_random_q` | LLM generates N random yes/no questions; UserProxy answers them |
| `best_of_n` | Iteratively generate, rank, and ask the best clarification question each round |
| `self_consistency` | Generate many candidates, cluster by embedding similarity, ask the consensus question |
| `dimension_aware_refinement` | Generate candidate specs, compute structural disagreements across resource/topology/attribute axes, rank by entropy with round-robin balancing, and ask targeted clarification questions |

### Options

| Flag | Description |
|------|-------------|
| `--dataset` | Dataset to use. Choices: `ambig-iac`, `multi-iac-updates`, `multi-iac-provision` (required) |
| `--method` | Clarification method (required) |
| `--max_questions` | Number of clarification rounds (required) |
| `--out_dir` | Output directory (required) |
| `--task_id` | Run a single task by ID (omit to run all) |
| `--n_candidates` | Candidate count for `best_of_n` / `self_consistency` (default: 3) |
| `--config` | Path to JSON config for per-role LLM settings |

### Output per task (`{out_dir}/{task_id}/`)

- `clarified_intent.txt` — Final clarified intent string
- `spec.json` — Generated infrastructure spec (resources, topology, attributes)
- `*_memory.json` — LLM conversation traces with token usage

### Example

```bash
uv run main.py --dataset ambig-iac --task_id 0 --max_questions 5 \
    --method best_of_n --n_candidates 3 --out_dir results/best_of_n/ --config configs/example.json
```

## Evaluation (`evaluate.py`)

Compare generated specs against ground-truth specs on two axes: **structure** (normalized graph edit distance) and **attributes** (embedding similarity).

```bash
# Evaluate all tasks that have spec.json in the target directory
uv run evaluate.py --dataset ambig-iac --target results/best_of_n/

# Evaluate a single task
uv run evaluate.py --dataset ambig-iac --target results/best_of_n/ --task_id 0
```

## Config

LLM settings are configured per role via a JSON file (see `configs/example.json`):

```json
{
  "model": "gpt-4o-mini",
  "temperature": 0.0,
  "proxy": {
    "model": "gpt-4o-mini",
    "temperature": 0.0
  }
}
```

## Project Structure

```
main.py                  # Clarification pipeline entry point
evaluate.py              # Spec evaluation (structure GED + attribute embedding similarity)
configs/example.json     # Per-role LLM config
scripts/run.sh           # Run all methods and evaluate
src/
  config.py              # Config loader + make_llm()
  cfg_state.py           # ConfigState / CheckResult dataclasses
  datasets.py            # IacEvalDataset loader
  spec_generator.py      # LLM-based spec generation and editing
  spec_converter.py      # plan.json ↔ Spec conversion, normalize_spec()
  spec_types.py          # Spec TypedDict
  user_proxy.py          # UserProxy (yes/no answerer)
  edit_actions.py        # Edit action grammar
  methods/               # Clarification methods
  evaluators/            # Evaluation checkers
  utils/
    llm.py               # Azure OpenAI LLM wrapper
    build_deps.py        # Terraform dependency graph builder
datasets/ambig-iac/      # Dataset: 300 tasks (prompt.txt, intent.txt, main.tf, plan.json, checks.rego)
```

## Citation

If you find this work useful, please cite:

```bibtex
@article{yang2025ambigiac,
  title={Ambig-IAC: Multi-level Disambiguation for Interactive Cloud Infrastructure-as-Code Synthesis},
  author={Yang, Zhenning and Gruizenga, Kaden and Miao, Tongyuan and Kon, Patrick Tser Jern and Chen, Ang and Guan, Hui},
  year={2025}
}
```

## License

MIT
