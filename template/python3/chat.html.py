# chat.html.py
# to run: python3 chat.html.py

import os
import re
from datetime import datetime
import git
import chardet
import argparse

# Debug flag
DEBUG = False

def debug_print(*args, **kwargs):
	if DEBUG:
		print(*args, **kwargs)

debug_print("Script started.")

def read_file(file_path):
	debug_print(f"Reading file: {file_path}")
	with open(file_path, 'r') as file:
		content = file.read()
	debug_print(f"File read successfully. Content length: {len(content)} characters")
	return content

def extract_metadata(content):
	debug_print("Extracting metadata from content")
	author = re.search(r'Author:\s*(.+)', content, re.IGNORECASE)
	author = author.group(1) if author else "Unknown"
	hashtags = re.findall(r'#\w+', content)
	debug_print(f"Extracted metadata - Author: {author}, Hashtags: {hashtags}")
	return author, hashtags

def truncate_message(content, max_length=300):
	debug_print(f"Truncating message. Original length: {len(content)}")
	if len(content) <= max_length:
		debug_print("Message does not need truncation")
		return content, False
	truncated = content[:max_length] + "..."
	debug_print(f"Message truncated. New length: {len(truncated)}")
	return truncated, True

import os
from os import scandir
import git
from datetime import datetime
import chardet

def generate_chat_html(repo_path, output_file, max_messages=50, max_message_length=300, title="THIMBLE Chat"):
	debug_print(f"Generating chat HTML. Repo path: {repo_path}, Output file: {output_file}")
	repo = git.Repo(repo_path)
	HTML_TEMPLATE = read_file('./template/html/chat_page.html')
	MESSAGE_TEMPLATE = read_file('./template/html/chat_message.html')
	CSS_STYLE = read_file('./template/css/chat_style.css')
	JS_TEMPLATE = read_file('./template/js/chat.js')

	messages = []
	message_dir = os.path.join(repo_path, "message")
	debug_print(f"Scanning directory: {message_dir}")

	def scan_directory(directory):
		debug_print(f"Scanning directory: {directory}")
		with scandir(directory) as entries:
			for entry in entries:
				if entry.is_file() and entry.name.endswith(".txt"):
					debug_print(f"Processing file: {entry.path}")
					process_file(entry.path)
				elif entry.is_dir():
					scan_directory(entry.path)

	def process_file(file_path):
		debug_print(f"Processing file: {file_path}")
		relative_path = os.path.relpath(file_path, repo_path)

		try:
			commit = next(repo.iter_commits(paths=relative_path, max_count=1))
			commit_timestamp = datetime.fromtimestamp(commit.committed_date)
			debug_print(f"Commit timestamp: {commit_timestamp}")
		except StopIteration:
			debug_print("No commit found for file, using minimum datetime")
			commit_timestamp = datetime.min

		try:
			with open(file_path, 'rb') as file:
				raw_data = file.read()
			detected_encoding = chardet.detect(raw_data)['encoding']
			debug_print(f"Detected encoding: {detected_encoding}")
			with open(file_path, 'r', encoding=detected_encoding, errors='ignore') as file:
				content = file.read()
			author, hashtags = extract_metadata(content)
		except Exception as e:
			debug_print(f"Error reading file {file_path}: {str(e)}")
			author = "Error"
			content = "Error reading message"
			hashtags = []

		content = re.sub(r'author:\s*.+', '', content, flags=re.IGNORECASE).strip()
		debug_print(f"Processed content. Length: {len(content)}")

		messages.append({
			'author': author,
			'content': content,
			'timestamp': commit_timestamp,
			'hashtags': hashtags
		})
		debug_print(f"Message added. Total messages: {len(messages)}")

	scan_directory(message_dir)

	debug_print("Sorting messages by timestamp")
	messages.sort(key=lambda x: x['timestamp'], reverse=True)

	# Limit the number of messages
	messages = messages[:max_messages]

	chat_messages = []
	for idx, msg in enumerate(messages):
		debug_print(f"Processing message {idx + 1}/{len(messages)}")
		truncated_content, is_truncated = truncate_message(msg['content'], max_message_length)
		expand_link = f'<a href="#" class="expand-link" data-message-id="{idx}">{"Show More" if is_truncated else ""}</a>'
		full_content = f'<div class="full-message" id="full-message-{idx}" style="display: none;">{msg["content"]}</div>' if is_truncated else ''

		chat_messages.append(MESSAGE_TEMPLATE.format(
			author=msg['author'],
			content=truncated_content,
			full_content=full_content,
			expand_link=expand_link,
			timestamp=msg['timestamp'].strftime('%Y-%m-%d %H:%M:%S'),
			hashtags=' '.join(msg['hashtags'])
		))

	debug_print("Generating final HTML content")
	html_content = HTML_TEMPLATE.format(
		style=CSS_STYLE,
		chat_messages=''.join(chat_messages),
		message_count=len(messages),
		current_time=datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
		title=title
	)

	html_content = html_content.replace('</body>', '<script>' + JS_TEMPLATE + '</script>' + '</body>')

	debug_print(f"Writing HTML content to file: {output_file}")
	with open(output_file, 'w', encoding='utf-8') as f:
		f.write(html_content)

if __name__ == "__main__":
	parser = argparse.ArgumentParser(description="Generate chat HTML from repository messages.")
	parser.add_argument("--repo_path", default=".", help="Path to the repository")
	parser.add_argument("--output_file", default="chat.html", help="Output HTML file name")
	parser.add_argument("--max_messages", type=int, default=50, help="Maximum number of messages to display")
	parser.add_argument("--max_message_length", type=int, default=300, help="Maximum length of each message before truncation")
	parser.add_argument("--title", default="THIMBLE Chat", help="Title of the chat page")
	parser.add_argument("--debug", action="store_true", help="Enable debug output")

	args = parser.parse_args()

	# Set the debug flag based on the command-line argument
	DEBUG = args.debug

	generate_chat_html(args.repo_path, args.output_file, args.max_messages, args.max_message_length, args.title)
	debug_print(f"Chat log generated: {args.output_file}")
	debug_print("Script completed.")

# end of chat.html.py