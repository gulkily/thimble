#!/bin/bash

./git-filter-repo --force --commit-callback '
import re
if commit.original_id == b"464fd2d1168a62b55153a27e97abf312df6763dd":
	tree = filter.get_tree(commit.tree)
	new_tree = []
	for entry in tree:
		if entry.name != b".":
			new_tree.append(entry)
	if len(new_tree) != len(tree):
		new_tree_id = filter.create_tree(new_tree)
		commit.tree = new_tree_id
'