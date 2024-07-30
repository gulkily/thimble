# start_server.py
# to run: python3 start_server.py

# start_server: v2

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


class CustomHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        self.directory = kwargs.pop("directory", os.getcwd())
        super().__init__(*args, directory=self.directory, **kwargs)

    def do_GET(self):
        if self.path == "/":
            super().do_GET()
        elif self.path == "/log.html":
            self.check_and_generate_report()
            super().do_GET()
        elif self.path == "/chat.html":
            self.check_and_generate_chat_html()
            super().do_GET()
        elif self.path.endswith(".txt"):
            self.serve_text_file()
        else:
            super().do_GET()

    def do_POST(self):
        if self.path == "/chat.html":
            self.handle_chat_post()
        else:
            self.send_error(405, "Method Not Allowed")

    def handle_chat_post(self):
        content_length = int(self.headers["Content-Length"])
        post_data = self.rfile.read(content_length).decode("utf-8")
        params = urllib.parse.parse_qs(post_data)

        author = params.get("author", [""])[0]
        message = params.get("message", [""])[0]

        if author and message:
            self.save_message(author, message)
            self.send_response(200)
            self.send_header("Content-type", "text/html")
            self.end_headers()
            self.wfile.write(b"Message saved successfully")
            # commit the message to the git repository using commit_files.py
            subprocess.run(["python", "commit_files.py", "message"], check=True)
            # redirect back to chat.html
            self.wfile.write(b'<meta http-equiv="refresh" content="1;url=/chat.html">')

        else:
            self.send_error(400, "Bad Request: Missing author or message")

    def save_message(self, author, message):
        today = datetime.now().strftime("%Y-%m-%d")
        directory = os.path.join(self.directory, "message", today)
        os.makedirs(directory, exist_ok=True)

        title = self.generate_title(message)
        filename = f"{title}.txt"
        filepath = os.path.join(directory, filename)

        with open(filepath, "w", encoding="utf-8") as f:
            f.write(message)
            f.write(f"\n\nauthor: {author}")

    def generate_title(self, message):
        words = message.split()[:5]
        title = "_".join(words)
        title = "".join(c for c in title if c.isalnum() or c in ["_", "-"])
        if not title:
            title = "".join(random.choices(string.ascii_lowercase, k=10))
        return title

    def check_and_generate_report(self):
        html_file = os.path.join(self.directory, "log.html")
        if (
            not os.path.exists(html_file)
            or time.time() - os.path.getmtime(html_file) > 60
        ):
            print(
                f"{html_file} is older than 60 seconds or does not exist. Running generate_report.py..."
            )
            subprocess.run(["python", "src/python/generate_report.py"], check=True)
        else:
            print(f"{html_file} is up-to-date.")

    def check_and_generate_chat_html(self):
        chat_html_file = os.path.join(self.directory, "chat.html")
        if (
            not os.path.exists(chat_html_file)
            or time.time() - os.path.getmtime(chat_html_file) > 60
        ):
            print(
                f"{chat_html_file} is older than 60 seconds or does not exist. Running generate_chat_html.py..."
            )
            subprocess.run(["python", "src/python/generate_chat_html.py"], check=True)
        else:
            print(f"{chat_html_file} is up-to-date.")

    def serve_text_file(self):
        path = self.translate_path(self.path)
        try:
            with open(path, "r", encoding="utf-8") as f:
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

            self.wfile.write(html_content.encode("utf-8"))
        except IOError:
            self.send_error(404, "File not found")


def run_server(port, directory):
    os.chdir(directory)
    handler = CustomHTTPRequestHandler
    httpd = socketserver.TCPServer(("", port), handler)
    try:
         print(f"Serving HTTP on 0.0.0.0 port {port} (http://0.0.0.0:{port}/) ...")
         httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    httpd.server_close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run a simple HTTP server.")
    parser.add_argument(
        "-p", "--port", type=int, default=8000, help="Port to serve on (default: 8000)"
    )
    parser.add_argument(
        "-d",
        "--directory",
        type=str,
        default=os.getcwd(),
        help="Directory to serve (default: current directory)",
    )

    args = parser.parse_args()

    run_server(args.port, args.directory)
