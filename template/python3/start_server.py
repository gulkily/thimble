#!/usr/bin/env python3

# start_server.py
# to run: python3 start_server.py

# start_server: v4

import http.server
import socketserver
import argparse
import os
import time
import subprocess
import html
import urllib.parse
from datetime import datetime
import random
import string
import socket

class CustomHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        self.directory = kwargs.pop('directory', os.getcwd())
        super().__init__(*args, directory=self.directory, **kwargs)

    def do_GET(self):
        if self.path == '/':
            self.serve_file('index.html')
        elif self.path == '/log.html':
            self.check_and_generate_report()
            self.serve_file('log.html')
        elif self.path == '/chat.html':
            self.check_and_generate_chat_html()
            self.serve_file('chat.html')
        elif self.path == '/api/github_update':
            self.handle_github_update()
        elif self.path.endswith('.txt'):
            self.serve_text_file()
        else:
            super().do_GET()

    def do_POST(self):
        if self.path == '/chat.html':
            self.handle_chat_post()
        else:
            self.send_error(405, "Method Not Allowed")

    def handle_github_update(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(b"Update triggered successfully")
        self.run_script('github_update')

    def handle_chat_post(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length).decode('utf-8')
        params = urllib.parse.parse_qs(post_data)

        author = params.get('author', [''])[0]
        message = params.get('message', [''])[0]

        if author and message:
            self.save_message(author, message)
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(b"Message saved successfully")
            self.wfile.write(b'<meta http-equiv="refresh" content="1;url=/chat.html">')
            self.run_script('commit_files', 'message')
            self.run_script('github_update')
        else:
            self.send_error(400, "Bad Request: Missing author or message")

    def save_message(self, author, message):
        today = datetime.now().strftime('%Y-%m-%d')
        directory = os.path.join(self.directory, 'message', today)
        os.makedirs(directory, exist_ok=True)

        title = self.generate_title(message)
        filename = f"{title}.txt"
        filepath = os.path.join(directory, filename)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(message)
            f.write(f"\n\nauthor: {author}")

    def generate_title(self, message):
        words = message.split()[:5]
        title = '_'.join(words)
        title = ''.join(c for c in title if c.isalnum() or c in ['_', '-'])
        if not title:
            title = ''.join(random.choices(string.ascii_lowercase, k=10))
        return title

    def check_and_generate_report(self):
        self.run_script_if_outdated('log.html', 'log.html')

    def check_and_generate_chat_html(self):
        self.run_script_if_outdated('chat.html', 'chat.html')

    def run_script_if_outdated(self, file_name, script_name):
        file_path = os.path.join(self.directory, file_name)
        if not os.path.exists(file_path) or time.time() - os.path.getmtime(file_path) > 60:
            print(f"{file_path} is older than 60 seconds or does not exist. Running {script_name}.py...")
            self.run_script(script_name)
        else:
            print(f"{file_path} is up-to-date.")

    def run_script(self, script_name, *args):
        script_types = ['py', 'pl', 'rb', 'sh', 'js']
        interpreters = ['python3', 'perl', 'ruby', 'bash', 'node']
        interpreter_map = dict(zip(script_types, interpreters))

        found_scripts = []

        for dir_name in os.listdir(os.path.join(self.directory, 'template')):
            for script_type in script_types:
                script_path = os.path.join(self.directory, 'template', dir_name, f"{script_name}.{script_type}")
                if os.path.isfile(script_path):
                    found_scripts.append(script_path)

        if not found_scripts:
            print(f"No scripts found for {script_name}")
            return

        for script in found_scripts:
            script_type = os.path.splitext(script)[1][1:]
            if script_type in interpreter_map:
                interpreter = interpreter_map[script_type]
                print(f"Running {script} with {interpreter}...")
                subprocess.run([interpreter, script] + list(args), check=True)
            else:
                print(f"No suitable interpreter found for {script}")

    def serve_file(self, path):
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

    def serve_text_file(self):
        path = self.translate_path(self.path)
        try:
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()

            self.send_response(200)
            self.send_header("Content-type", "text/html; charset=utf-8")
            self.end_headers()

            html_content = f"""
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>{os.path.basename(path)}</title>
                <style>
                    body {{ font-family: Arial, sans-serif; line-height: 1.6; padding: 20px; }}
                    pre {{ background-color: #f4f4f4; padding: 15px; border-radius: 5px; white-space: pre-wrap; word-wrap: break-word; }}
                </style>
            </head>
            <body>
                <h1>{os.path.basename(path)}</h1>
                <pre>{html.escape(content)}</pre>
            </body>
            </html>
            """

            self.wfile.write(html_content.encode('utf-8'))
        except IOError:
            self.send_error(404, "File not found")

    def get_content_type(self, file_path):
        mime_types = {
            'txt': 'text/plain',
            'html': 'text/html',
            'css': 'text/css',
            'js': 'application/javascript',
            'json': 'application/json',
            'png': 'image/png',
            'jpg': 'image/jpeg',
            'gif': 'image/gif',
        }
        ext = os.path.splitext(file_path)[1][1:].lower()
        return mime_types.get(ext, 'application/octet-stream')

def is_port_in_use(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex(('localhost', port)) == 0

def find_available_port(start_port):
    port = start_port
    while is_port_in_use(port):
        port += 1
    return port

def run_server(port, directory):
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