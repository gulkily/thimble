# generate_report.py
# to run: python3 generate_report.py

import os
import re
from datetime import datetime
import git
import gnupg
import traceback
import chardet

def read_file(file_path):
    with open(file_path, 'r') as file:
        return file.read()

def extract_metadata(content):
    author = re.search(r'Author:\s*(.+)', content, re.IGNORECASE)
    author = author.group(1) if author else ""
    hashtags = re.findall(r'#\w+', content)
    return author, hashtags

def generate_html(repo_path, output_file):
    repo = git.Repo(repo_path)
    HTML_TEMPLATE = read_file('./template/html/page.html')
    TABLE_ROW_TEMPLATE = read_file('./template/html/page_row.html')
    CSS_STYLE = read_file('./template/css/webmail.css')

    file_info = []
    file_count = 0
    for root, dirs, files in os.walk(repo_path):
        for file in files:
            if file.endswith(".txt"):
                file_path = os.path.join(root, file)
                relative_path = os.path.relpath(file_path, repo_path)

                try:
                    commit = next(repo.iter_commits(paths=relative_path, max_count=1))
                    commit_timestamp = datetime.fromtimestamp(commit.committed_date)
                except StopIteration:
                    commit_timestamp = datetime.min

                stored_date = os.path.basename(os.path.dirname(file_path))
                try:
                    with open(file_path, 'rb') as file:
                        raw_data = file.read()
                    detected_encoding = chardet.detect(raw_data)['encoding']
                    with open(file_path, 'r', encoding=detected_encoding, errors='ignore') as file:
                        content = file.read()
                    author, hashtags = extract_metadata(content)
                except Exception as e:
                    print(f"Error reading file {file_path}: {str(e)}")
                    author = "Error"
                    hashtags = []

                file_info.append({
                    'relative_path': relative_path,
                    'commit_timestamp': commit_timestamp,
                    'stored_date': stored_date,
                    'author': author,
                    'hashtags': hashtags
                })

                file_count += 1
                if file_count >= 100:
                    break

        if file_count >= 100:
            break

    # Sort the file_info list by commit_timestamp in descending order
    file_info.sort(key=lambda x: x['commit_timestamp'], reverse=True)

    table_rows = []
    for info in file_info:
        table_rows.append(TABLE_ROW_TEMPLATE.format(
            relative_path=info['relative_path'],
            commit_timestamp=info['commit_timestamp'].strftime('%Y-%m-%d %H:%M:%S'),
            stored_date=info['stored_date'],
            author=info['author'],
            hashtags=', '.join(info['hashtags'])
        ))

    html_content = HTML_TEMPLATE.format(
        style=CSS_STYLE,
        table_rows=''.join(table_rows),
        file_count=file_count,
        current_time=datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        title="THIMBLE"
    )

    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(html_content)

if __name__ == "__main__":
    repo_path = "./message"
    output_file = 'log.html'
    generate_html(repo_path, output_file)
    print(f"Report generated: {output_file}")

