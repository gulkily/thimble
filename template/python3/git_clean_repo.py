#!/usr/bin/env python3
import os
import subprocess
from tempfile import NamedTemporaryFile

def fix_tree(tree_id):
	"""Recursively creates new tree objects without problematic entries."""

	print(f"Fixing tree {tree_id}...")

	tree_content = subprocess.check_output(["git", "cat-file", "-p", tree_id]).decode()

	with NamedTemporaryFile(mode="w") as temp_file:
	for line in tree_content.splitlines():
	    mode, type_, hash_, path = line.split(maxsplit=3)

	    if path.startswith("./"):
		print(f"Removing problematic entry: {path}")
		continue

	    # Recursively fix subtrees if necessary
	    if type_ == "tree":
		fix_tree(hash_)

	    temp_file.write(f"{mode} {type_} {hash_} {path}\n")
	temp_file.flush()

	# Create new tree and replace
	new_tree_id = subprocess.check_output(
	    ["git", "mktree"], input=temp_file.name.encode()
	).decode().strip()
	subprocess.check_call(["git", "replace", tree_id, new_tree_id])


# Backup the repository before making changes
backup_dir = f"../git_backup_{os.path.basename(os.getcwd())}_" + \
	     subprocess.check_output(["date", "+%Y%m%d_%H%M%S"]).decode().strip()
print(f"Creating backup of the repository at {backup_dir}")
subprocess.check_call(["cp", "-r", ".git", backup_dir])

# Check for corrupted objects
print("Running git fsck to find corrupted objects...")
fsck_output = subprocess.check_output(["git", "fsck"]).decode()

# Find and fix trees with 'hasDot' warnings
print("Finding and fixing trees with 'hasDot' warning...")
for line in fsck_output.splitlines():
	if "hasDot" in line:
	tree_id = line.split()[2]
	fix_tree(tree_id)

# Prune loose objects and repack (with more conservative options)
print("Pruning and repacking the repository...")
subprocess.check_call(["git", "prune"])
subprocess.check_call(["git", "gc"])

# Verify again
print("Running git fsck again to verify...")
subprocess.check_call(["git", "fsck"])

print("Cleanup complete. You can now try pushing to the repository.")