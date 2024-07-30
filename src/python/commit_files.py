# commit_files.py
# to run: python3 commit_files.py

import os
import re
import subprocess
from datetime import datetime
import json
import hashlib

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

def run_git_command(command):
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    output, error = process.communicate()
    return output.decode('utf-8').strip(), error.decode('utf-8').strip()

def commit_text_files(repo_path="."):
    os.chdir(repo_path)

    # Check if there are any changes
    status_output, _ = run_git_command("git status --porcelain")
    if not status_output:
        print("No changes to commit.")
        return

    # Get all modified and untracked files
    changed_files, _ = run_git_command("git diff --name-only")
    untracked_files, _ = run_git_command("git ls-files --others --exclude-standard")

    all_files = changed_files.split('\n') + untracked_files.split('\n')
    txt_files = [f for f in all_files if f.endswith('.txt')]

    if not txt_files:
        print("No uncommitted .txt files found.")
        return

    # Process each file and store metadata
    metadata_files = []
    for file_path in txt_files:
        full_path = os.path.join(repo_path, file_path)
        try:
            with open(full_path, 'r', encoding='utf-8') as f:
                content = f.read()

            metadata = extract_metadata(content, full_path)
            metadata_file = store_metadata(full_path, metadata)
            metadata_files.append(metadata_file)

            print(f"File: {file_path}")
            print(f"Author: {metadata['author']}")
            print(f"Title: {metadata['title']}")
            print(f"Hashtags: {', '.join(metadata['hashtags'])}")
            print(f"File Hash: {metadata['file_hash']}")
            print()
        except Exception as e:
            print(f"Error processing file {file_path}: {str(e)}")

    # Add all .txt files and metadata files to staging
    files_to_add = txt_files + metadata_files
    for file in files_to_add:
        run_git_command(f"git add {file}")

    # Create commit message
    commit_message = f"Auto-commit {len(txt_files)} text files and metadata on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} by commit_files.py"

    # Commit the changes
    run_git_command(f'git commit -m "{commit_message}"')

    print(f"Committed {len(txt_files)} text files and their metadata.")
    print("Commit message:", commit_message)

if __name__ == "__main__":
    commit_text_files(repo_path="message")
