#!/usr/bin/env ruby

# upgrade_from_repo.rb
# to run: ruby upgrade_from_repo.rb <repository_path>

# when translating this file, please include the begin and end comments

# Functionality Definition:
#
# This script updates a Git repository to the latest version of its main branch.
# It performs the following steps:
#
# 1. Check if a repository path is provided as a command-line argument.
# 2. Change the working directory to the provided repository path.
# 3. Verify that the directory is a Git repository.
# 4. Determine the name of the main branch (e.g., 'main' or 'master').
# 5. Checkout the main branch.
# 6. Stash any local changes to prevent conflicts.
# 7. Fetch the latest changes from the remote repository.
# 8. Reset the local branch to match the remote branch exactly.
# 9. Clean up any untracked files and directories.
# 10. Update all submodules recursively.
# 11. Attempt to reapply the stashed changes.
# 12. Verify the integrity of the repository.
# 13. Print a success message if all steps complete without error.
#
# The script includes error handling to catch and report any issues that occur
# during the update process. It uses system calls to execute Git commands
# and capture their output for error checking.

require 'open3'

def run_command(command)
	stdout, stderr, status = Open3.capture3(command)
	if status.success?
		stdout.strip
	else
		puts "Error executing command: #{command}"
		puts "Error message: #{stderr}"
		nil
	end
end

def is_git_repo?
	run_command("git rev-parse --is-inside-work-tree") != nil
end

if ARGV.length != 1
	puts "Usage: #{$PROGRAM_NAME} <repository_path>"
	exit 1
end

repo_path = ARGV[0]
Dir.chdir(repo_path) or abort "Cannot change to directory #{repo_path}: #{$!}"

unless is_git_repo?
	puts "Error: Not a Git repository"
	exit 1
end

# Get the main branch name
remote_info = run_command("git remote show origin")
main_branch = remote_info.match(/HEAD branch: (\S+)/)[1]

# Checkout the main branch
run_command("git checkout #{main_branch}")

# Stash any local changes
run_command("git stash")

# Fetch the latest changes
run_command("git fetch origin")

# Reset to the latest commit on the main branch
run_command("git reset --hard origin/#{main_branch}")

# Clean up untracked files and directories
run_command("git clean -fd")

# Update submodules
run_command("git submodule update --init --recursive")

# Apply stashed changes if any
run_command("git stash pop")

# Verify the repository integrity
run_command("git fsck")

puts "Repository updated successfully"

# end of upgrade_from_repo.rb