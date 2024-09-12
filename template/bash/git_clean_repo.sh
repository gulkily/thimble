#!/bin/bash

# Function to create a new tree object without problematic entries
fix_tree() {
	local tree_id=$1
	echo "Fixing tree $tree_id..."

	# Get tree content
	tree_content=$(git cat-file -p "$tree_id")

	# Create a temporary file
	temp_file=$(mktemp)

	# Filter out and fix problematic entries
	while IFS= read -r line; do
		mode=$(echo "$line" | cut -d' ' -f1)
		type=$(echo "$line" | cut -d' ' -f2)
		hash=$(echo "$line" | cut -d' ' -f3)
		path=$(echo "$line" | cut -d' ' -f4-)

		if [[ "$path" == .\/* ]]; then
			echo "Removing problematic entry: $path"
			continue  # Skip this entry
		fi

		# Add valid entries to the new tree
		echo "$mode $type $hash $path" >> "$temp_file"
	done <<< "$tree_content"

	# Create new tree and replace
	new_tree_id=$(git mktree < "$temp_file")
	git replace "$tree_id" "$new_tree_id"

	# Clean up
	rm "$temp_file"
}

# Backup the repository before making changes
echo "Creating backup of the repository..."
cp -r .git ../git_backup_$(date +%Y%m%d_%H%M%S)

# Check for corrupted objects
echo "Running git fsck to find corrupted objects..."
git fsck > fsck_output.txt

# Find objects with 'hasDot' warnings and process directly
echo "Finding and fixing trees with 'hasDot' warning..."
while IFS= read -r line; do
	tree_id=$(echo "$line" | awk '{print $3}')
	fix_tree "$tree_id"
done < <(grep 'hasDot' fsck_output.txt)

# Prune loose objects and repack (with more conservative options)
echo "Pruning and repacking the repository..."
git prune
git gc

# Verify again
echo "Running git fsck again to verify..."
git fsck

echo "Cleanup complete. You can now try pushing to the repository."