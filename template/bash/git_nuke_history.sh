#!/bin/bash

echo "Warning: This script will reset all git history."
echo "To run this script, comment the line which exits."

# Step 1: Backup current branch
git checkout -b backup-branch

# Step 2: Recreate main branch without problematic commits
git checkout --orphan new-main

# Step 3: Add all files to new branch
git add .

# Step 4: Commit the changes
git commit -m "Recreate main branch without invalid directory"

# Step 5: Delete the old main branch and rename the new branch
git branch -D main
git branch -m main

# Step 6: Push the new main branch
git push -f origin main

# Step 7: Clean up dangling objects (optional)
git reflog expire --expire=now --all
git gc --prune=now --aggressive