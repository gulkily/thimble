#!/usr/bin/env python3
# github_update.py
# to run: python3 github_update.py [--debug]

import os
import subprocess
import sys
import argparse

DEBUG = False

def debug_print(message):
    if DEBUG:
        print(f"DEBUG: {message}")

def run_git_command(command):
    debug_print(f"Running command: {command}")
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    output, error = process.communicate()
    debug_print(f"Command output: {output.decode('utf-8').strip()}")
    debug_print(f"Command error: {error.decode('utf-8').strip()}")
    return output.decode('utf-8').strip(), error.decode('utf-8').strip()

def check_for_uncommitted_changes():
    print("Checking for uncommitted changes...")
    status_output, _ = run_git_command("git status --porcelain")
    if status_output:
        print("Uncommitted changes found.")
    else:
        print("No uncommitted changes.")
    return bool(status_output)

def stash_changes():
    print("Stashing local changes...")
    output, error = run_git_command("git stash")
    if "No local changes to save" in output:
        print("No changes to stash.")
    elif error:
        print(f"Error stashing changes: {error}")
        sys.exit(1)
    else:
        print("Changes stashed successfully.")

def pop_stashed_changes():
    print("Applying stashed changes...")
    output, error = run_git_command("git stash pop")
    if "No stash entries found" in error:
        print("No stashed changes to apply.")
    elif error and "CONFLICT" not in error:
        print(f"Error applying stashed changes: {error}")
        sys.exit(1)
    elif "CONFLICT" in error:
        print("Conflicts occurred while applying stashed changes. Please resolve manually.")
    else:
        print("Stashed changes applied successfully.")

def fetch_remote():
    print("Fetching remote changes...")
    output, error = run_git_command("git fetch")
    if error:
        print(f"Error fetching remote: {error}")
        sys.exit(1)
    print("Remote changes fetched successfully.")

def check_for_diverged_history():
    print("Checking for diverged history...")
    local_commit, _ = run_git_command("git rev-parse HEAD")
    remote_commit, _ = run_git_command("git rev-parse @{u}")
    diverged = local_commit != remote_commit
    if diverged:
        print("Local and remote histories have diverged.")
    else:
        print("Local and remote histories are in sync.")
    return diverged

def merge_remote_changes():
    print("Merging remote changes...")
    output, error = run_git_command("git merge origin/main")
    if "CONFLICT" in output or "CONFLICT" in error:
        print("Merge conflict detected. Please resolve conflicts manually.")
        sys.exit(1)
    elif error:
        print(f"Error merging changes: {error}")
        sys.exit(1)
    else:
        print("Remote changes merged successfully.")

def push_changes():
    print("Pushing local changes to remote...")
    output, error = run_git_command("git push")
    if error:
        print(f"Error pushing changes: {error}")
        sys.exit(1)
    print("Local changes pushed successfully.")

def github_update():
    # Check for uncommitted changes
    if check_for_uncommitted_changes():
        stash_changes()
        stashed = True
    else:
        stashed = False

    # Fetch remote changes
    fetch_remote()

    # Check for diverged history
    if check_for_diverged_history():
        merge_remote_changes()

    # Push local changes
    push_changes()

    # Apply stashed changes if any
    if stashed:
        pop_stashed_changes()

    print("GitHub repository updated successfully.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Update GitHub repository")
    parser.add_argument("--debug", action="store_true", help="Enable debug output")
    args = parser.parse_args()

    DEBUG = args.debug

    github_update()