# chat.html.py
# to run: python3 chat.html.py

import os
import re
from datetime import datetime
import chardet
import argparse
from multiprocessing import Pool
from functools import partial

DEBUG = False

def debug_print(*args, **kwargs):
    if DEBUG:
        print(*args, **kwargs)

def read_file(file_path):
    with open(file_path, 'r') as file:
        return file.read()

# Compile regular expressions once
author_regex = re.compile(r'Author:\s*(.+)', re.IGNORECASE)
hashtag_regex = re.compile(r'#\w+')

def extract_metadata(content):
    author = author_regex.search(content)
    author = author.group(1) if author else "Unknown"
    hashtags = hashtag_regex.findall(content)
    return author, hashtags

def truncate_message(content, max_length=300):
    if len(content) <= max_length:
        return content, False
    return content[:max_length] + "...", True

def process_file(file_path, repo_path):
    relative_path = os.path.relpath(file_path, repo_path)
    try:
        creation_time = datetime.fromtimestamp(os.path.getctime(file_path))
        with open(file_path, 'rb') as file:
            raw_data = file.read(1024)  # Read only first 1024 bytes for encoding detection
        detected_encoding = chardet.detect(raw_data)['encoding']
        with open(file_path, 'r', encoding=detected_encoding, errors='ignore') as file:
            content = file.read()
        author, hashtags = extract_metadata(content)
        content = re.sub(r'author:\s*.+', '', content, flags=re.IGNORECASE).strip()
        return {
            'author': author,
            'content': content,
            'timestamp': creation_time,
            'hashtags': hashtags
        }
    except Exception as e:
        debug_print(f"Error reading file {file_path}: {str(e)}")
        return None

def generate_chat_html(repo_path, output_file, max_messages=50, max_message_length=300, title="THIMBLE Chat"):
    HTML_TEMPLATE = read_file('./template/html/chat_page.html')
    MESSAGE_TEMPLATE = read_file('./template/html/chat_message.html')
    CSS_STYLE = read_file('./template/css/chat_style.css')
    JS_TEMPLATE = read_file('./template/js/chat.js')

    message_dir = os.path.join(repo_path, "message")

    file_paths = []
    for root, _, files in os.walk(message_dir):
        for file in files:
            if file.endswith(".txt"):
                file_paths.append(os.path.join(root, file))

    with Pool() as pool:
        messages = pool.map(partial(process_file, repo_path=repo_path), file_paths)

    messages = [msg for msg in messages if msg is not None]
    messages.sort(key=lambda x: x['timestamp'], reverse=True)
    messages = messages[:max_messages]

    chat_messages = []
    for idx, msg in enumerate(messages):
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

    html_content = HTML_TEMPLATE.format(
        style=CSS_STYLE,
        chat_messages=''.join(chat_messages),
        message_count=len(messages),
        current_time=datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        title=title
    )

    html_content = html_content.replace('</body>', f'<script>{JS_TEMPLATE}</script></body>')

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
    DEBUG = args.debug

    generate_chat_html(args.repo_path, args.output_file, args.max_messages, args.max_message_length, args.title)
    debug_print(f"Chat log generated: {args.output_file}")
    debug_print("Script completed.")

# end of chat.html.py