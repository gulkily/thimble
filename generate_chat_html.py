# generate_chat_html.py
# to run: python3 generate_chat_html.py

import os
import re
from datetime import datetime
import git
import chardet

def read_file(file_path):
	with open(file_path, 'r') as file:
		return file.read()

def extract_metadata(content):
	author = re.search(r'Author:\s*(.+)', content, re.IGNORECASE)
	author = author.group(1) if author else "Unknown"
	hashtags = re.findall(r'#\w+', content)
	return author, hashtags

def truncate_message(content, max_length=300):
	if len(content) <= max_length:
		return content, False
	return content[:max_length] + "...", True

import os
from os import scandir
import git
from datetime import datetime
import chardet

def generate_chat_html(repo_path, output_file):
	repo = git.Repo(repo_path)
	HTML_TEMPLATE = read_file('./template/html/chat_page.html')
	MESSAGE_TEMPLATE = read_file('./template/html/chat_message.html')
	CSS_STYLE = read_file('./template/css/chat_style.css')
	JS_TEMPLATE = read_file('./template/js/chat.js')

	messages = []
	message_dir = os.path.join(repo_path, "message")

	def scan_directory(directory):
		with scandir(directory) as entries:
			for entry in entries:
				if entry.is_file() and entry.name.endswith(".txt"):
					process_file(entry.path)
				elif entry.is_dir():
					scan_directory(entry.path)

	def process_file(file_path):
		relative_path = os.path.relpath(file_path, repo_path)

		try:
			commit = next(repo.iter_commits(paths=relative_path, max_count=1))
			commit_timestamp = datetime.fromtimestamp(commit.committed_date)
		except StopIteration:
			commit_timestamp = datetime.min

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
			content = "Error reading message"
			hashtags = []

		messages.append({
			'author': author,
			'content': content,
			'timestamp': commit_timestamp,
			'hashtags': hashtags
		})

	scan_directory(message_dir)

	# Sort messages by timestamp in ascending order
	messages.sort(key=lambda x: x['timestamp'])

	chat_messages = []
	for idx, msg in enumerate(messages):
		truncated_content, is_truncated = truncate_message(msg['content'])
		expand_link = f'<a href="#" class="expand-link" data-message-id="{idx}">{"Show More" if is_truncated else "Show Less"}</a>'
		full_content = f'<div class="full-message" id="full-message-{idx}" style="display: none;">{msg["content"]}</div>' if is_truncated else ''

		chat_messages.append(MESSAGE_TEMPLATE.format(
			author=msg['author'],
			content=truncated_content,
			full_content=full_content,
			expand_link=expand_link,
			timestamp=msg['timestamp'].strftime('%Y-%m-%d %H:%M:%S'),
			hashtags=' '.join(msg['hashtags'])
		))

	html_content = HTML_TEMPLATE.format(
		style=CSS_STYLE,
		chat_messages=''.join(chat_messages),
		message_count=len(messages),
		current_time=datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
		title="THIMBLE Chat"
	)

	html_content = html_content.replace('</body>', '<script>' + JS_TEMPLATE + '</script>' + '</body>')

	with open(output_file, 'w', encoding='utf-8') as f:
		f.write(html_content)

if __name__ == "__main__":
	repo_path = "."  # Current directory
	output_file = 'chat.html'
	generate_chat_html(repo_path, output_file)
	print(f"Chat log generated: {output_file}")