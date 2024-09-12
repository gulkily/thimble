#!/bin/bash

# upgrade_from_repo.sh
# to run: bash upgrade_from_repo.sh <repository_path>

# Functionality Definition:
#
# This script is designed to update a Git repository to the latest version of its main branch.
# It performs the following operations:
#
# 1. Accepts a repository path as a command-line argument.
# 2. Changes the working directory to the specified repository path.
# 3. Checks if the specified path is a valid Git repository.
# 4. Determines the name of the main branch (e.g., 'main' or 'master').
# 5. Switches to the main branch.
# 6. Stashes any local changes to prevent conflicts.
# 7. Fetches the latest changes from the remote repository.
# 8. Resets the local branch to match the remote branch exactly.
# 9. Cleans up any untracked files and directories.
# 10. Updates all submodules recursively.
# 11. Attempts to reapply the stashed changes (if any).
# 12. Verifies the integrity of the repository.
# 13. Prints a success message if all operations complete without errors.
#
# The script uses error handling to exit if any step fails, ensuring the repository
# is left in a consistent state. It's designed to be run from the command line and
# requires Git to be installed and accessible in the system's PATH.

set -e

repo_path="$1"
if [ -z "$repo_path" ]; then
	echo "Usage: $0 <repository_path>"
	exit 1
fi

cd "$repo_path"

# Function to check if we're in a Git repository
is_git_repo() {
	git rev-parse --is-inside-work-tree &>/dev/null
}

# Check if we're in a Git repository
if ! is_git_repo; then
	echo "Error: Not a Git repository"
	exit 1
fi

# Ensure we're on the main branch
main_branch=$(git remote show origin | sed -n '/HEAD branch/s/.*: //p')
git checkout "$main_branch"

# Stash any local changes
git stash

# Fetch the latest changes
git fetch origin

# Reset to the latest commit on the main branch
git reset --hard "origin/$main_branch"

# Clean up untracked files and directories
git clean -fd

# Update submodules
git submodule update --init --recursive

# Apply stashed changes if any
git stash pop || true

# Verify the repository integrity
git fsck

echo "Repository updated successfully"

# end of upgrade_from_repo.sh