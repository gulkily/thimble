#!/usr/bin/env python3

import os
import sys
import subprocess

def run_command(command):
    try:
        result = subprocess.run(command, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {' '.join(command)}")
        print(f"Error message: {e.stderr}")
        return None

def is_git_repo():
    return run_command(["git", "rev-parse", "--is-inside-work-tree"]) is not None

def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <repository_path>")
        sys.exit(1)

    repo_path = sys.argv[1]
    os.chdir(repo_path)

    if not is_git_repo():
        print("Error: Not a Git repository")
        sys.exit(1)

    # Get the main branch name
    main_branch = run_command(["git", "remote", "show", "origin"]).split("\n")
    main_branch = [line.split()[-1] for line in main_branch if "HEAD branch" in line][0]

    # Checkout the main branch
    run_command(["git", "checkout", main_branch])

    # Stash any local changes
    run_command(["git", "stash"])

    # Fetch the latest changes
    run_command(["git", "fetch", "origin"])

    # Reset to the latest commit on the main branch
    run_command(["git", "reset", "--hard", f"origin/{main_branch}"])

    # Clean up untracked files and directories
    run_command(["git", "clean", "-fd"])

    # Update submodules
    run_command(["git", "submodule", "update", "--init", "--recursive"])

    # Apply stashed changes if any
    run_command(["git", "stash", "pop"])

    # Verify the repository integrity
    run_command(["git", "fsck"])

    print("Repository updated successfully")

if __name__ == "__main__":
    main()
