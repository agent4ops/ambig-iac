"""
A base dataloader class that provides a common interface for all dataloaders.

Usage:

from src.datasets import (
    IacEvalDataset,
    MultiIacProvisionDataset,
    MultiIacUpdatesDataset,
)

dataset = IacEvalDataset(dataset_root="datasets/iac-eval-verified/")
dataset = MultiIacProvisionDataset(dataset_root="datasets/multi-iac-provision/")
dataset = MultiIacUpdatesDataset(dataset_root="datasets/multi-iac-updates/")

# in loop:
for task in dataset:
    program = generator(task)
    feedback = evaluator.eval_program(program)
    print(feedback)
"""

import json
import os
from pathlib import Path

from src.spec_converter import plan_to_spec


class BaseDataset:
    """
    A base dataset class that provides a common interface for all datasets.
    """

    def __init__(self, dataset_root: Path):
        self.dataset_root = dataset_root
        self.tasks = []
        self.index_to_target_dir = {}

    def __len__(self) -> int:
        return len(self.tasks)

    def __getitem__(self, index: int) -> str:
        return self.tasks[index]

    def __iter__(self):
        return iter(self.tasks)

    def get_target_dir(self, index: int) -> Path:
        return self.index_to_target_dir[index]


class IacEvalDataset(BaseDataset):
    """
    A dataset class for the IaC evaluation dataset.
    """

    def __init__(self, dataset_root: str):
        super().__init__(dataset_root=Path(dataset_root))
        self.tasks = []
        self.tasks_dict_list = []

        # check if the dataset root exists
        if not self.dataset_root.is_dir():
            raise NotADirectoryError(
                f"Dataset root {self.dataset_root} is not a directory"
            )
        else:
            self._load_dataset()

    def _load_dataset(self):
        """
        Load the dataset from the dataset root directory.
        """
        try:
            # try sorting the subdirectories by integer
            subdirs_list = sorted(os.listdir(self.dataset_root), key=lambda x: int(x))
        except:
            subdirs_list = sorted(os.listdir(self.dataset_root))

        # loop through 1 level deep subdirectories and load the tasks
        for index, task_dir in enumerate(subdirs_list):
            task_dir = Path(self.dataset_root / task_dir)
            # print(f"Loading task from {task_dir}")
            if task_dir.is_dir():
                self._load_task(task_dir, index)
        print(f"Loaded {len(self.tasks)} tasks from {self.dataset_root}")

    def _load_task(self, task_dir: Path, index: int):
        """
        Load one task from a subdirectory.

        should contain:
        - prompt.txt
        - intent.txt
        - checks.rego
        - main.tf
        - plan.json
        - graph.dot (optional)
        """
        task_dict = {
            "abs_path": task_dir.absolute(),
            "prompt": task_dir / "prompt.txt",
            "intent": task_dir / "intent.txt",
            "checks": task_dir / "checks.rego",
            "main": task_dir / "main.tf",
            "plan": task_dir / "plan.json",
        }

        # check if all files exist, and read the prompts
        for file in task_dict.values():
            if not file.exists():
                raise FileNotFoundError(f"File {file} not found")

        self.tasks_dict_list.append(task_dict)
        task_prompt = task_dict["prompt"].read_text().strip()
        self.tasks.append(task_prompt)

        self.index_to_target_dir[index] = task_dict["abs_path"]

    def get_intent(self, index: int) -> str:
        """Return the intent.txt content for the task at the given index."""
        return self.tasks_dict_list[index]["intent"].read_text().strip()


def _sorted_task_dirs(dataset_root: Path) -> list[str]:
    try:
        return sorted(os.listdir(dataset_root), key=lambda x: int(x))
    except Exception:
        return sorted(os.listdir(dataset_root))


class MultiIacProvisionDataset(BaseDataset):
    def __init__(self, dataset_root: str):
        super().__init__(dataset_root=Path(dataset_root))
        self.tasks = []
        self.tasks_dict_list = []

        if not self.dataset_root.is_dir():
            raise NotADirectoryError(
                f"Dataset root {self.dataset_root} is not a directory"
            )
        self._load_dataset()

    def _load_dataset(self) -> None:
        subdirs_list = _sorted_task_dirs(self.dataset_root)

        for index, task_dir in enumerate(subdirs_list):
            task_path = self.dataset_root / task_dir
            if task_path.is_dir():
                self._load_task(task_path, index)
        print(f"Loaded {len(self.tasks)} tasks from {self.dataset_root}")

    def _load_task(self, task_dir: Path, index: int) -> None:
        task_dict = {
            "abs_path": task_dir.absolute(),
            "prompt": task_dir / "prompt.txt",
            "main": task_dir / "main.tf",
            "plan": task_dir / "plan.json",
        }

        for file in task_dict.values():
            if not file.exists():
                raise FileNotFoundError(f"File {file} not found")

        self.tasks_dict_list.append(task_dict)
        self.tasks.append(task_dict["prompt"].read_text().strip())
        self.index_to_target_dir[index] = task_dict["abs_path"]


class MultiIacUpdatesDataset(BaseDataset):
    def __init__(self, dataset_root: str, use_spec: bool = True):
        super().__init__(dataset_root=Path(dataset_root))
        self.tasks = []
        self.tasks_dict_list = []
        self.use_spec = use_spec
        
        if not self.dataset_root.is_dir():
            raise NotADirectoryError(
                f"Dataset root {self.dataset_root} is not a directory"
            )
        self._load_dataset()

    def _load_dataset(self) -> None:
        subdirs_list = _sorted_task_dirs(self.dataset_root)

        for index, task_dir in enumerate(subdirs_list):
            task_path = self.dataset_root / task_dir
            if task_path.is_dir():
                self._load_task(task_path, index)
        print(f"Loaded {len(self.tasks)} tasks from {self.dataset_root}")

    def _load_task(self, task_dir: Path, index: int) -> None:
        task_dict = {
            "abs_path": task_dir.absolute(),
            "prompt": task_dir / "prompt.txt",
            "main": task_dir / "main.tf",
            "plan": task_dir / "plan.json",
            "initial": task_dir / "initial.tf",
            "initial_prompt": task_dir / "initial_prompt.txt",
            "initial_plan": task_dir / "initial_plan.json",
        }

        for file in task_dict.values():
            if not file.exists():
                raise FileNotFoundError(f"File {file} not found")

        self.tasks_dict_list.append(task_dict)
        # self.tasks.append(task_dict["prompt"].read_text().strip())
        # for update append the initial tf to the prompt
        if self.use_spec:
            spec_str = json.dumps(plan_to_spec(task_dict["initial_plan"]), indent=4)
            task_prompt_with_iac = f"Task prompt: {task_dict['prompt'].read_text().strip()}\n\nInitial IaC Spec:\n{spec_str}"
        else:
            tf_str = task_dict["initial"].read_text().strip()
            task_prompt_with_iac = f"Task prompt: {task_dict['prompt'].read_text().strip()}\n\nInitial IaC:\n{tf_str}"
        
        self.tasks.append(task_prompt_with_iac)
        self.index_to_target_dir[index] = task_dict["abs_path"]

