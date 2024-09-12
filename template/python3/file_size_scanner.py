# file_size_scanner.py
# to run: python3 file_size_scanner.py
# show the total size of files with specific extensions
# and list the files in descending order of size
# also list and compare files with the same filename but different extensions
#
# file_size_scanner: v2

import os
import glob
from collections import defaultdict

def get_file_size(file_path):
	"""Get the size of a file in bytes."""
	return os.path.getsize(file_path)

def format_size(size):
	"""Format the file size for consistent output."""
	return f"{size:15d}"

def scan_files(extensions):
	"""Scan files with given extensions and collect size information."""
	# Initialize dictionaries to store file data and same-name files
	file_data = {ext: {'total_size': 0, 'files': []} for ext in extensions}
	same_name_files = defaultdict(list)

	# Iterate through each extension
	for ext in extensions:
		# Use glob to find all files with the current extension
		for file_path in glob.glob(f"**/*.{ext}", recursive=True):
			size = get_file_size(file_path)
			# Update total size and file list for the current extension
			file_data[ext]['total_size'] += size
			file_data[ext]['files'].append((file_path, size))

			# Store files with the same name but different extensions
			file_name = os.path.splitext(os.path.basename(file_path))[0]
			same_name_files[file_name].append((file_path, ext, size))

	return file_data, same_name_files

def display_results(file_data, same_name_files):
	"""Display the results of the file scan."""
	# Print total size for each extension
	print("Extension  Total Size")
	print("-" * 25)
	for ext, data in file_data.items():
		print(f"{ext:9s}  {format_size(data['total_size'])}")

	# Print file listing by extension, sorted by size
	print("\nFile Listing by Extension:")
	for ext, data in file_data.items():
		if data['files']:
			print(f"\n.{ext} files:")
			sorted_files = sorted(data['files'], key=lambda x: x[1], reverse=True)
			for file_path, size in sorted_files:
				print(f"{format_size(size)} {file_path}")

	# Print files with the same name but different extensions
	print("\nFiles with the same name but different extensions:")
	for file_name, files in same_name_files.items():
		if len(files) > 1:
			print(f"\n{file_name}:")
			for file_path, ext, size in sorted(files, key=lambda x: x[2], reverse=True):
				print(f"{ext:4s} {format_size(size)} {file_path}")

if __name__ == "__main__":
	# List of file extensions to scan
	extensions = ['py', 'php', 'js', 'sh', 'pl', 'rb']
	# Scan files and get results
	file_data, same_name_files = scan_files(extensions)
	# Display the results
	display_results(file_data, same_name_files)