#!/usr/bin/env python3

import os
import sys

def standardize_line_endings(file_path):
	# Read the file content
	with open(file_path, 'rb') as file:
		content = file.read()

	# Convert all line endings to LF
	content = content.replace(b'\r\n', b'\n').replace(b'\r', b'\n')

	# Write the standardized content back to the file
	with open(file_path, 'wb') as file:
		file.write(content)

def process_directory(directory):
	for root, dirs, files in os.walk(directory):
		for file in files:
			if file.endswith(('.py', '.js', '.sh', '.txt', '.html', '.php', '.pl', '.rb', '.css')):
				file_path = os.path.join(root, file)
				print(f"Standardizing line endings in: {file_path}")
				standardize_line_endings(file_path)

if __name__ == "__main__":
	if len(sys.argv) != 2:
		print("Usage: python fix_line_endings.py <directory>")
		sys.exit(1)

	directory = sys.argv[1]
	if not os.path.isdir(directory):
		print(f"Error: {directory} is not a valid directory")
		sys.exit(1)

	process_directory(directory)
	print("Line ending standardization complete.")