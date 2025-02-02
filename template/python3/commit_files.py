# commit_files.py
# to run: python3 commit_files.py

# File: commit_files.py
# Description: A script to automatically commit text files and their metadata to a Git repository.
#
# Dependencies:
# - Python 3.x
# - Git (installed and configured)
#
# Main functions:
# - calculate_file_hash(file_path): Calculates SHA256 hash of a file
# - extract_metadata(content, file_path): Extracts metadata from file content
# - store_metadata(file_path, metadata): Stores metadata as JSON file
# - run_git_command(command, repo_path): Executes Git commands
# - commit_text_files(repo_path="."): Main function to process and commit files
#
# Usage: python3 commit_files.py
#
# The script does the following:
# 1. Finds all modified and untracked .txt files in the repository
# 2. Extracts metadata (author, title, hashtags, file hash) from each file
# 3. Stores metadata in JSON files in a 'metadata' directory
# 4. Adds all .txt files and metadata files to Git staging
# 5. Creates a commit with an auto-generated message
#
# Note: This script should be run from within a Git repository

import os
import re
import subprocess
import sys
from datetime import datetime
import json
import hashlib
import shlex

def calculate_file_hash(file_path):
	sha256_hash = hashlib.sha256()
	with open(file_path, "rb") as f:
		for byte_block in iter(lambda: f.read(4096), b""):
			sha256_hash.update(byte_block)
	return sha256_hash.hexdigest()

def extract_metadata(content, file_path):
	metadata = {
		'author': '',
		'title': os.path.basename(file_path),
		'hashtags': [],
		'file_hash': calculate_file_hash(file_path)
	}

	# Extract author
	author_match = re.search(r'Author:\s*(.+)', content)
	if author_match:
		metadata['author'] = author_match.group(1)

	# Extract title (assuming it's the first line of the file)
	title_match = re.search(r'^(.+)', content)
	if title_match:
		metadata['title'] = title_match.group(1).strip()

	# Extract hashtags
	metadata['hashtags'] = re.findall(r'#\w+', content)

	return metadata

def store_metadata(file_path, metadata):
	metadata_dir = os.path.join(os.path.dirname(file_path), 'metadata')
	os.makedirs(metadata_dir, exist_ok=True)

	metadata_file = os.path.join(metadata_dir, f"{os.path.basename(file_path)}.json")

	with open(metadata_file, 'w', encoding='utf-8') as f:
		json.dump(metadata, f, indent=2)

	return metadata_file

def run_git_command(command, repo_path):
	process = subprocess.Popen(f"git -C {shlex.quote(repo_path)} {command}", stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
	output, error = process.communicate()
	return output.decode('utf-8').strip(), error.decode('utf-8').strip()

def commit_text_files(repo_path="."):
	repo_path = os.path.abspath(repo_path)

	try:
		# Check if there are any changes
		status_output, _ = run_git_command("status --porcelain", repo_path)
		if not status_output:
			print("No changes to commit.")
			return

		# Get modified and untracked files
		changed_files, _ = run_git_command("diff --name-only", repo_path)
		untracked_files, _ = run_git_command("ls-files --others --exclude-standard", repo_path)

		all_files = changed_files.split('\n') + untracked_files.split('\n')
		txt_files = [f for f in all_files if f.endswith('.txt')]

		if not txt_files:
			print("No uncommitted .txt files found.")
			return

		for file_path in txt_files:
			try:
				abs_path = os.path.join(repo_path, file_path)
				with open(abs_path, 'r', encoding='utf-8') as f:
					content = f.read()

				metadata = extract_metadata(content, abs_path)
				metadata_file = store_metadata(abs_path, metadata)

				print(f"File: {file_path}")
				print(f"Author: {metadata['author']}")
				print(f"Title: {metadata['title']}")
				print(f"Hashtags: {', '.join(metadata['hashtags'])}")
				print(f"File Hash: {metadata['file_hash']}")
				print()

				rel_metadata = os.path.relpath(metadata_file, repo_path)
				run_git_command(f"add {shlex.quote(file_path)} {shlex.quote(rel_metadata)}", repo_path)
			except Exception as e:
				print(f"Error processing file {file_path}: {str(e)}")

		# Create commit
		timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
		commit_message = f"Auto-commit {len(txt_files)} text files and metadata on {timestamp} by commit_files.py"
		run_git_command(f"commit -m {shlex.quote(commit_message)}", repo_path)

		print(f"Committed {len(txt_files)} text files and their metadata.")
		print(f"Commit message: {commit_message}")
	finally:
		pass

if __name__ == "__main__":
	repo_path = sys.argv[1] if len(sys.argv) > 1 else "."
	commit_text_files(repo_path=repo_path)

# end of commit_files.py