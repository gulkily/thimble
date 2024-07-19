import http.server
import socketserver
import argparse
import os
import time
import subprocess

class CustomHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        self.directory = kwargs.pop('directory', os.getcwd())
        super().__init__(*args, directory=self.directory, **kwargs)

    def do_GET(self):
        if self.path == '/':
            self.check_and_generate_report()
            super().do_GET()
        elif self.path.endswith('.txt'):
            self.serve_text_file()
        else:
            super().do_GET()

    def check_and_generate_report(self):
        html_file = os.path.join(self.directory, 'repository_files.html')
        if not os.path.exists(html_file) or time.time() - os.path.getmtime(html_file) > 60:
            print(f"{html_file} is older than 60 seconds or does not exist. Running generate_report.py...")
            subprocess.run(['python', 'generate_report.py'], check=True)
        else:
            print(f"{html_file} is up-to-date.")

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



def run_server(port, directory):
    os.chdir(directory)
    handler = CustomHTTPRequestHandler
    with socketserver.TCPServer(("", port), handler) as httpd:
        print(f"Serving HTTP on 0.0.0.0 port {port} (http://0.0.0.0:{port}/) ...")
        httpd.serve_forever()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run a simple HTTP server.")
    parser.add_argument('-p', '--port', type=int, default=8000, help='Port to serve on (default: 8000)')
    parser.add_argument('-d', '--directory', type=str, default=os.getcwd(), help='Directory to serve (default: current directory)')

    args = parser.parse_args()
    
    run_server(args.port, args.directory)

