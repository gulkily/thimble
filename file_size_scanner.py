# file_size_scanner.py
# to run: python3 file_size_scanner.py
# show the total size of files with specific extensions
# and list the files in descending order of size
#
# file_size_scanner: v1

import os
import glob

def get_file_size(file_path):
    return os.path.getsize(file_path)

def format_size(size):
    return f"{size:15d}"

def scan_files(extensions):
    file_data = {ext: {'total_size': 0, 'files': []} for ext in extensions}

    for ext in extensions:
        for file_path in glob.glob(f"**/*.{ext}", recursive=True):
            size = get_file_size(file_path)
            file_data[ext]['total_size'] += size
            file_data[ext]['files'].append((file_path, size))

    return file_data

def display_results(file_data):
    print("Extension  Total Size")
    print("-" * 25)
    for ext, data in file_data.items():
        print(f"{ext:9s}  {format_size(data['total_size'])}")
    
    print("\nFile Listing by Extension:")
    for ext, data in file_data.items():
        if data['files']:
            print(f"\n.{ext} files:")
            sorted_files = sorted(data['files'], key=lambda x: x[1], reverse=True)
            for file_path, size in sorted_files:
                print(f"{format_size(size)} {file_path}")

if __name__ == "__main__":
    extensions = ['py', 'php', 'js', 'sh', 'pl', 'rb']
    file_data = scan_files(extensions)
    display_results(file_data)
