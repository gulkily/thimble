#!/bin/bash

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
