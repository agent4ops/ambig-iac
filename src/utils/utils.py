"""
Utility functions for the project. 
"""

import os
import shutil
import tempfile
import argparse
from pathlib import Path


# helper functions
def is_awscc(prompt: str) -> bool:
    """
    Determine if the prompt is for an AWSCC task.
    """
    # handling the mulit-iac-updates dataset
    if "initial iac" in prompt.lower():
        # removing the initial iac from the prompt
        task_prompt = prompt.lower().split("initial iac")[0].strip()
        return "awscc" in task_prompt.lower()
    return "awscc" in prompt.lower()

def tmp_tf_workspace(program: str, workspace_dir: Path = Path("tmp")) -> Path:
    """
    Create a unique temporary workspace directory and write the program to main.tf.

    Each call creates a new subdirectory under workspace_dir so that concurrent
    terraform runs do not collide on state locks or plugin caches.
    """
    workspace_dir.mkdir(parents=True, exist_ok=True)
    workspace_path = Path(tempfile.mkdtemp(dir=workspace_dir))
    with open(workspace_path / "main.tf", "w") as f:
        f.write(program)
    return workspace_path

def cleanup_terraform(workspace_dir: str, verbose: bool = True) -> None:
    """
    Cleanup the terraform workspace directory.

    - remove .terraform/ directory
    - remove .terraform.lock.hcl file
    - remove plan.out file
    - remove policy.rego file
    - remove graph.dot file
    """
    terraform_dir = os.path.join(workspace_dir, ".terraform")
    if os.path.exists(terraform_dir):
        if verbose:
            print(f"Removing: {terraform_dir}")
        shutil.rmtree(terraform_dir, ignore_errors=True)
    
    # Remove individual files
    # files_to_remove = [".terraform.lock.hcl", "plan.out", "plan.json", "policy.rego", "graph.dot"]
    files_to_remove = [".terraform.lock.hcl", "plan.out", "tfplan"]
    for filename in files_to_remove:
        file_path = os.path.join(workspace_dir, filename)
        if os.path.exists(file_path):
            try:
                if verbose:
                    print(f"Removing: {file_path}")
                os.remove(file_path)
            except Exception:
                pass


def cleanup_terraform_recursive(workspace_dir: str, level: int = 0, max_level: int = 3) -> None:
    """
    Recursively cleanup terraform workspace directories up to max_level depth.

    Args:
        workspace_dir: The directory to clean up
        level: Current recursion level (default: 0)
        max_level: Maximum recursion depth (default: 3)
    """
    if level > max_level:
        return
    
    # Cleanup current directory
    try:
        cleanup_terraform(workspace_dir)
    except Exception:
        pass
    
    # Recursively cleanup subdirectories
    if level < max_level:
        try:
            for item in os.listdir(workspace_dir):
                item_path = os.path.join(workspace_dir, item)
                if os.path.isdir(item_path):
                    cleanup_terraform_recursive(item_path, level + 1, max_level)
        except (OSError, PermissionError):
            pass


def main():
    """
    Main function to recursively clean up terraform workspaces in a directory.
    """
    parser = argparse.ArgumentParser(
        description="Recursively clean up terraform workspace directories"
    )
    parser.add_argument(
        "directory",
        type=str,
        help="Path to the directory to clean up"
    )
    args = parser.parse_args()
    
    directory_path = os.path.abspath(args.directory)
    
    if not os.path.exists(directory_path):
        print(f"Error: Directory does not exist: {directory_path}")
        return
    
    if not os.path.isdir(directory_path):
        print(f"Error: Path is not a directory: {directory_path}")
        return
    
    print(f"Cleaning up terraform workspaces in: {directory_path}")
    cleanup_terraform_recursive(directory_path)
    print("Cleanup completed.")


if __name__ == "__main__":
    main()
