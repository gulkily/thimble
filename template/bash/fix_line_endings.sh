#!/bin/bash

standardize_line_endings() {
	local file="$1"
	# Use sed to replace CRLF with LF, then use tr to replace any remaining CR with LF
	sed -i 's/\r$//' "$file"
	tr '\r' '\n' < "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
}

process_directory() {
	local dir="$1"
	
	find "$dir" -type f \( -name "*.py" -o -name "*.js" -o -name "*.php" -o -name "*.pl" -o -name "*.rb" -o -name "*.css" -o -name "*.sh" -o -name "*.txt" -o -name "*.html" \) | while read -r file; do
		echo "Standardizing line endings in: $file"
		standardize_line_endings "$file"
	done
}

if [ $# -ne 1 ]; then
	echo "Usage: $0 <directory>"
	exit 1
fi

directory="$1"

if [ ! -d "$directory" ]; then
	echo "Error: $directory is not a valid directory"
	exit 1
fi

process_directory "$directory"
echo "Line ending standardization complete."