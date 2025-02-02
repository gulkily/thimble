#!/bin/bash

# Create a new test repository
REPO_NAME=$1

# Create the repository directory
mkdir -p $REPO_NAME

# Initialize git repository
cd $REPO_NAME
git init
git config user.name "Test User"
git config user.email "test@example.com"

# Create initial commit
echo "# Test Repository" > README.md
git add README.md
git commit -m "Initial commit"
