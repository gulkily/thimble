import os
import subprocess
import re
import shutil
import tempfile

def run_command(command, check=True):
	"""Run a shell command and return its output."""
	print(f"Running command: {command}")
	result = subprocess.run(command, shell=True, check=check, text=True, capture_output=True)
	print(f"Command output: {result.stdout}")
	if result.stderr:
		print(f"Command error: {result.stderr}")
	return result

def get_problematic_commits():
	"""Get a list of commits with the '.' file issue."""
	output = run_command("git fsck", check=False).stdout
	commits = re.findall(r"warning in tree ([a-f0-9]+): hasDot: contains '\.'", output)
	print(f"Found {len(commits)} problematic commits")
	return commits

def create_temp_branch(commit):
	"""Create a temporary branch for a given commit."""
	branch_name = f"fix_dot_{commit[:7]}"
	run_command(f"git checkout -b {branch_name} {commit}")
	return branch_name

def remove_dot_file():
	"""Remove the '.' file from the current commit."""
	if os.path.exists('.'):
		print("Removing '.' file")
		os.remove('.')
	else:
		print("'.' file not found in current directory")

def amend_commit():
	"""Amend the current commit to remove the '.' file."""
	run_command("git commit --amend -C HEAD --allow-empty")

def main():
	print("Starting the fix process...")

	# Ensure we're in a git repository
	if not os.path.exists('.git'):
		print("Error: Not in a git repository")
		return

	# Get the current branch
	current_branch = run_command("git rev-parse --abbrev-ref HEAD").stdout.strip()
	print(f"Current branch: {current_branch}")

	# Get problematic commits
	commits = get_problematic_commits()

	if not commits:
		print("No problematic commits found. Exiting.")
		return

	# Create a temporary directory for our work
	with tempfile.TemporaryDirectory() as temp_dir:
		print(f"Created temporary directory: {temp_dir}")

		# Copy the .git directory to our temporary directory
		shutil.copytree('.git', os.path.join(temp_dir, '.git'))
		os.chdir(temp_dir)
		print(f"Working in temporary directory: {os.getcwd()}")

		for commit in commits:
			print(f"\nProcessing commit: {commit}")

			# Create a temporary branch
			temp_branch = create_temp_branch(commit)

			# Remove the '.' file
			remove_dot_file()

			# Amend the commit
			amend_commit()

			# Get the new commit hash
			new_commit = run_command("git rev-parse HEAD").stdout.strip()

			# Force update the branch to point to the new commit
			run_command(f"git update-ref refs/heads/{current_branch} {new_commit}")

			# Clean up: delete the temporary branch
			run_command(f"git checkout {current_branch}")
			run_command(f"git branch -D {temp_branch}")

		print("\nAll commits processed. Returning to original directory.")

	# Return to the original directory
	os.chdir('..')
	print(f"Back in original directory: {os.getcwd()}")

	# Final fsck to check if all issues are resolved
	print("\nRunning final git fsck:")
	run_command("git fsck", check=False)

	print("\nProcess completed. Please review the changes and ensure everything is correct.")

if __name__ == "__main__":
	main()