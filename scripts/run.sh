#!/bin/bash

# Run all methods on Ambig-IaC and evaluate
# Usage: bash scripts/run.sh

dataset="ambig-iac"
result_dir="results/${dataset}/"
config="configs/example.json"
n_candidates=10
max_questions=10

# Direct (no clarification)
uv run main.py --dataset ${dataset} --method direct --max_questions 1 \
                --out_dir ${result_dir}/direct/ --config ${config} --continue
uv run evaluate.py --dataset ${dataset} --target ${result_dir}/direct/ --continue

# Baselines
for method in direct_random_q best_of_n self_consistency; do
    uv run main.py --dataset ${dataset} --method ${method} \
                    --max_questions ${max_questions} --n_candidates ${n_candidates} \
                    --out_dir ${result_dir}/${method}/ --config ${config} --continue
    uv run evaluate.py --dataset ${dataset} --target ${result_dir}/${method}/ --continue
done

# Ours
uv run main.py --dataset ${dataset} --method dimension_aware_refinement \
                --max_questions ${max_questions} \
                --out_dir ${result_dir}/dimension_aware_refinement/ --config ${config} --continue
uv run evaluate.py --dataset ${dataset} --target ${result_dir}/dimension_aware_refinement/ --continue
