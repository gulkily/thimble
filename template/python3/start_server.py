#!/usr/bin/env python3

# start_server.py
# to run: python3 start_server.py

# start_server: v4

import argparse
import html
import http.server
import os
import random
import socket
import socketserver
import string
import subprocess
import time
import urllib.parse
from datetime import datetime
from typing import List, Tuple

# Configuration constants
SCRIPT_TYPES = ['py', 'pl', 'rb', 'sh', 'js']
INTERPRETERS = ['python3', 'perl', 'ruby', 'bash', 'node']
INTERPRETER_MAP = dict(zip(SCRIPT_TYPES, INTERPRETERS))
MIME_TYPES = {
    'txt': 'text/plain',
    'html': 'text/html',
    'css': 'text/css',
    'js': 'application/javascript',
    'json': 'application/json',
    'png': 'image/png',
    'jpg': 'image/jpeg',
    'gif': 'image/gif',
}

class CustomHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        self.directory = kwargs.pop('directory', os.getcwd())
        super().__init__(*args, directory=self.directory, **kwargs)

    def do_GET(self):
        """Handle GET requests"""
        if self.path in ['/', '/index.html']:
            self.serve_static_file('index.html')
        elif self.path == '/log.html':
            self.generate_and_serve_report()
        elif self.path == '/chat.html':
            self.generate_and_serve_chat()
        elif self.path == '/api/github_update':
            self.trigger_github_update()
        elif self.path.endswith('.txt'):
            self.serve_text_file_as_html()
        else:
            self.serve_static_file(self.path[1:])

    def do_POST(self):
        """Handle POST requests"""
        if self.path == '/chat.html':
            self.handle_chat_post()
        else:
            self.send_error(405, "Method Not Allowed")

    def trigger_github_update(self):
        """Trigger GitHub update and run the corresponding script"""
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(b"Update triggered successfully")
        self.run_script('github_update')

    def handle_chat_post(self):
        """Handle POST request for chat messages"""
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length).decode('utf-8')
        params = urllib.parse.parse_qs(post_data)

        author = params.get('author', [''])[0]
        message = params.get('message', [''])[0]

        if not author or not message:
            self.send_error(400, "Bad Request: Missing author or message")
            return

        self.save_message(author, message)
        self.send_response(302)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(b"Message saved successfully")
        self.wfile.write(b'<meta http-equiv="refresh" content="1;url=/chat.html">')
        self.run_script('commit_files', 'message')
        self.run_script('github_update')

    def save_message(self, author: str, message: str):
        """Save a chat message to a file"""
        timestamp = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
        title = self.generate_title(message)
        filename = f"{timestamp}_{title}.txt"

        message_dir = os.path.join(self.directory, 'message')
        os.makedirs(message_dir, exist_ok=True)

        filepath = os.path.join(message_dir, filename)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(f"{message}\n\nAuthor: {author}")

    def generate_title(self, message: str) -> str:
        """Generate a title for the message file"""
        if not message:
            return ''.join(random.choices(string.ascii_lowercase, k=10))

        words = message.split()[:5]
        title = '_'.join(words)
        safe_title = ''.join(c for c in title if c.isalnum() or c in ['_', '-'])
        return safe_title

    def generate_and_serve_report(self):
        """Generate and serve the log report"""
        self.run_script_if_needed('log.html', 'log.html')
        self.serve_static_file('log.html')

    def generate_and_serve_chat(self):
        """Generate and serve the chat page"""
        self.run_script_if_needed('chat.html', 'chat.html')
        self.serve_static_file('chat.html')

    def run_script_if_needed(self, output_filename: str, script_name: str):
        """Run a script if the output file doesn't exist or is outdated"""
        output_filepath = os.path.join(self.directory, output_filename)
        if not os.path.exists(output_filepath) or \
           time.time() - os.path.getmtime(output_filepath) > 60:
            print(f"Generating {output_filename}...")
            self.run_script(script_name)

    def run_script(self, script_name: str, *args):
        """Run a script with the appropriate interpreter"""
        found_scripts = self.find_scripts(script_name)

        if not found_scripts:
            print(f"No scripts found for {script_name}")
            return

        for script_path, script_type in found_scripts:
            interpreter = INTERPRETER_MAP.get(script_type)
            if interpreter:
                subprocess.run([interpreter, script_path, *args], cwd=self.directory)

    def find_scripts(self, script_name: str) -> List[Tuple[str, str]]:
        """Find all scripts matching the given name"""
        found_scripts = []
        for template_dir in os.listdir(os.path.join(self.directory, 'template')):
            for script_type in SCRIPT_TYPES:
                script_path = os.path.join(self.directory, 'template', template_dir, f"{script_name}.{script_type}")
                if os.path.exists(script_path):
                    found_scripts.append((script_path, script_type))
        return found_scripts

    def serve_text_file_as_html(self):
        """Serve a text file as HTML"""
        path = os.path.join(self.directory, self.path[1:])
        try:
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()

            self.send_response(200)
            self.send_header("Content-type", "text/html; charset=utf-8")
            self.end_headers()

            escaped_content = html.escape(content)
            html_content = self.generate_html_content(os.path.basename(path), escaped_content)
            self.wfile.write(html_content.encode('utf-8'))
        except IOError:
            self.send_error(404, "File not found")

    def generate_html_content(self, title: str, content: str) -> str:
        """Generate HTML content for displaying text files"""
        return f"""
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>{title}</title>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; padding: 20px; }}
                pre {{ background-color: #f4f4f4; padding: 15px; border-radius: 5px; white-space: pre-wrap; word-wrap: break-word; }}
            </style>
        </head>
        <body>
            <h1>{title}</h1>
            <pre>{content}</pre>
        </body>
        </html>
        """

    def serve_static_file(self, path: str):
        """Serve a static file"""
        file_path = os.path.join(self.directory, path)
        if os.path.isfile(file_path):
            with open(file_path, 'rb') as f:
                content = f.read()
            content_type = self.get_content_type(file_path)
            self.send_response(200)
            self.send_header('Content-type', content_type)
            self.end_headers()
            self.wfile.write(content)
        else:
            self.send_error(404)

    def get_content_type(self, file_path: str) -> str:
        """Get the content type for a file"""
        ext = os.path.splitext(file_path)[1][1:].lower()
        return MIME_TYPES.get(ext, 'application/octet-stream')

def is_port_in_use(port: int) -> bool:
    """Check if a port is already in use"""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex(('localhost', port)) == 0

def find_available_port(start_port: int) -> int:
    """Find an available port starting from the given port"""
    port = start_port
    while is_port_in_use(port):
        port += 1
    return port

def run_server(port: int, directory: str) -> bool:
    """Run the HTTP server"""
    os.chdir(directory)
    handler = CustomHTTPRequestHandler
    try:
        with socketserver.TCPServer(("", port), handler) as httpd:
            print(f"Serving HTTP on 0.0.0.0 port {port} (http://0.0.0.0:{port}/) ...")
            httpd.serve_forever()
    except OSError as e:
        if e.errno == 98:  # Address already in use
            print(f"Port {port} is already in use.")
            return False
    return True

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run a simple HTTP server.")
    parser.add_argument('-p', '--port', type=int, default=8000, help='Port to serve on (default: 8000)')
    parser.add_argument('-d', '--directory', type=str, default=os.getcwd(), help='Directory to serve (default: current directory)')

    args = parser.parse_args()

    if is_port_in_use(args.port):
        print(f"Port {args.port} is already in use.")
        args.port = find_available_port(args.port + 1)
        print(f"Trying port {args.port}...")

    run_server(args.port, args.directory)

# end of start_server.py