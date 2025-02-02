# test_commit_files.py
# to run: python3 test_commit_files.py

import os
import subprocess
import json
import random
import string
from datetime import datetime

def random_string(length=8) -> str:
	return ''.join(random.choices(string.ascii_lowercase + string.digits, k=length))

def create_test_file(content: str, test_repo_dir: str) -> str:
	filename = f"test_{random_string()}.txt"
	file_path = os.path.join(test_repo_dir, "message", filename)
	os.makedirs(os.path.dirname(file_path), exist_ok=True)
	
	content = f"""Author: Test Author
Title: Test Title

{content}

#test #metadata"""

	with open(file_path, 'w', encoding='utf-8') as f:
		f.write(content)
	
	return file_path

def run_commit_files(script: str):
	try:
		repo_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
		subprocess.run(["bash", "-c", f"cd {repo_dir} && source thimble.sh && t commit"], check=True, capture_output=True, text=True)
		return True
	except subprocess.CalledProcessError as e:
		print(f"Error: {e.stderr}")
		return False

def check_git_log(test_repo_dir) -> bool:
	curr_dir = os.getcwd()
	os.chdir(test_repo_dir)
	result = subprocess.run(["git", "log", "-1", "--pretty=format:%s"], capture_output=True, text=True)
	os.chdir(curr_dir)
	return "Auto-commit" in result.stdout

def check_metadata_file(filename: str) -> bool:
	repo_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
	metadata_file = os.path.join(repo_dir, "message", "metadata", os.path.basename(filename) + ".json")
	if not os.path.exists(metadata_file):
		print(f"Metadata file not found: {metadata_file}")
		return False
	try:
		with open(metadata_file, 'r') as f:
			metadata = json.load(f)
		return all(key in metadata for key in ['author', 'title', 'hashtags', 'file_hash'])
	except Exception as e:
		print(f"Error reading metadata file: {e}")
		return False

def run_tests(script: str, test_repo_dir: str) -> None:
	print(f"Testing commit files functionality")
	
	# Create test file
	test_file = create_test_file("Test content\nWith multiple lines", test_repo_dir)
	
	# Run commit_files
	if not run_commit_files(script):
		print("Error: Failed to run commit_files")
		return
	
	# Check git log
	if not check_git_log(test_repo_dir):
		print("Error: Git commit not found or invalid commit message")
		return
	
	# Check metadata file
	if not check_metadata_file(test_file):
		print("Error: Metadata file not created or invalid")
		return
	
	print("All tests passed!")

if __name__ == "__main__":
	repo_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
	run_tests("", repo_dir)