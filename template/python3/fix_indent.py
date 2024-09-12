#!/usr/bin/env python3

# fix_indent.py
# to use: python3 fix_indent.py <directory>

import os
import sys
import re

def convert_spaces_to_tabs(file_path):
	# Read the file content
	with open(file_path, 'r') as file:
		content = file.read()

	# Detect the most common space indentation
	space_indents = re.findall(r'^ +', content, re.MULTILINE)
	if space_indents:
		most_common_indent = max(set(space_indents), key=space_indents.count)
		spaces_per_indent = len(most_common_indent)
	else:
		spaces_per_indent = 4  # Default to 4 spaces if no indentation is found

	# Replace space indentation with tabs
	lines = content.split('\n')
	converted_lines = []
	for line in lines:
		indent_count = 0
		while line.startswith(' ' * spaces_per_indent):
			indent_count += 1
			line = line[spaces_per_indent:]
		converted_lines.append('\t' * indent_count + line)

	# Join the lines and write back to the file
	converted_content = '\n'.join(converted_lines)
	with open(file_path, 'w') as file:
		file.write(converted_content)

def process_directory(directory):
	for root, dirs, files in os.walk(directory):
		for file in files:
			if file.endswith(('.py', '.js', '.sh', '.txt', '.html', '.php', '.pl', '.rb', '.css')):
				file_path = os.path.join(root, file)
				print(f"Converting space indentation to tabs in: {file_path}")
				convert_spaces_to_tabs(file_path)

if __name__ == "__main__":
	if len(sys.argv) != 2:
		print("Usage: python convert_indentation.py <directory>")
		sys.exit(1)

	directory = sys.argv[1]
	if not os.path.isdir(directory):
		print(f"Error: {directory} is not a valid directory")
		sys.exit(1)

	process_directory(directory)
	print("Indentation conversion complete.")

# end fix_indent.py