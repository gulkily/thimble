const http = require('http');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const { escape } = require('html-escaper');

class CustomHTTPRequestHandler {
  constructor(req, res) {
    this.req = req;
    this.res = res;
    this.directory = process.cwd();
  }

  handleRequest() {
    if (this.req.url === '/') {
      this.checkAndGenerateReport();
      this.serveFile('repository_files.html');
    } else if (this.req.url.endsWith('.txt')) {
      this.serveTextFile();
    } else {
      this.serveFile(this.req.url.slice(1));
    }
  }

  checkAndGenerateReport() {
    const htmlFile = path.join(this.directory, 'repository_files.html');
    fs.stat(htmlFile, (err, stats) => {
      if (err || Date.now() - stats.mtime.getTime() > 60000) {
        console.log(`${htmlFile} is older than 60 seconds or does not exist. Running generate_report.js...`);
        exec('node generate_report.js', (error, stdout, stderr) => {
          if (error) {
            console.error(`Error: ${error.message}`);
            return;
          }
          if (stderr) {
            console.error(`Error: ${stderr}`);
            return;
          }
          console.log(`Output: ${stdout}`);
        });
      } else {
        console.log(`${htmlFile} is up-to-date.`);
      }
    });
  }

  serveTextFile() {
    const filePath = path.join(this.directory, this.req.url.slice(1));
    fs.readFile(filePath, 'utf8', (err, content) => {
      if (err) {
        this.sendError(404, 'File not found');
        return;
      }

      const htmlContent = `
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>${path.basename(filePath)}</title>
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; padding: 20px; }
                pre { background-color: #f4f4f4; padding: 15px; border-radius: 5px; white-space: pre-wrap; word-wrap: break-word; }
            </style>
        </head>
        <body>
            <h1>${path.basename(filePath)}</h1>
            <pre>${escape(content)}</pre>
        </body>
        </html>
      `;

      this.res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
      this.res.end(htmlContent);
    });
  }

  serveFile(fileName) {
    const filePath = path.join(this.directory, fileName);
    fs.readFile(filePath, (err, content) => {
      if (err) {
        this.sendError(404, 'File not found');
        return;
      }

      const ext = path.extname(filePath).toLowerCase();
      const contentType = {
        '.html': 'text/html',
        '.js': 'text/javascript',
        '.css': 'text/css',
        '.json': 'application/json',
        '.png': 'image/png',
        '.jpg': 'image/jpeg',
        '.gif': 'image/gif',
      }[ext] || 'application/octet-stream';

      this.res.writeHead(200, { 'Content-Type': contentType });
      this.res.end(content);
    });
  }

  sendError(statusCode, message) {
    this.res.writeHead(statusCode, { 'Content-Type': 'text/plain' });
    this.res.end(message);
  }
}

function runServer(port, directory) {
  process.chdir(directory);
  const server = http.createServer((req, res) => {
    const handler = new CustomHTTPRequestHandler(req, res);
    handler.handleRequest();
  });

  server.listen(port, () => {
    console.log(`Serving HTTP on 0.0.0.0 port ${port} (http://0.0.0.0:${port}/) ...`);
  });
}

function parseArguments() {
  const args = process.argv.slice(2);
  let port = 8000;
  let directory = process.cwd();

  for (let i = 0; i < args.length; i += 2) {
    if (args[i] === '-p' || args[i] === '--port') {
      port = parseInt(args[i + 1]);
    } else if (args[i] === '-d' || args[i] === '--directory') {
      directory = args[i + 1];
    }
  }

  return { port, directory };
}

const { port, directory } = parseArguments();
runServer(port, directory);
