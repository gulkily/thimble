#!/usr/bin/env python3

# upgrade_from_repo.py
# to run: python3 upgrade_from_repo.py <repository_path>

# Functionality Definition:
#
# This script updates a Git repository to the latest version of its main branch.
# It performs the following steps:
#
# 1. Check if the correct number of command-line arguments is provided.
# 2. Change the current working directory to the specified repository path.
# 3. Verify that the specified path is a Git repository.
# 4. Determine the name of the main branch (e.g., main or master).
# 5. Checkout the main branch.
# 6. Stash any local changes to prevent conflicts.
# 7. Fetch the latest changes from the remote repository.
# 8. Reset the local branch to match the remote branch exactly.
# 9. Clean up any untracked files and directories.
# 10. Update all submodules recursively.
# 11. Attempt to reapply any stashed changes.
# 12. Verify the integrity of the repository.
# 13. Print a success message if all steps complete without errors.
#
# The script uses subprocess to run Git commands and handles potential errors.
# It's designed to be run from the command line with the repository path as an argument.
#

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

# end of upgrade_from_repo.py