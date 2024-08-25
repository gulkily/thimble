// start_server.js
// to run: node start_server.js

// start_server: v3

const http = require('http');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const { escape } = require('html-escaper');
const querystring = require('querystring');
const { DateTime } = require('luxon');

class CustomHTTPRequestHandler {
  constructor(req, res) {
    this.req = req;
    this.res = res;
    this.directory = process.cwd();
  }

  handleRequest() {
    if (this.req.method === 'GET') {
      this.handleGet();
    } else if (this.req.method === 'POST') {
      this.handlePost();
    } else {
      this.sendError(405, "Method Not Allowed");
    }
  }

  handleGet() {
    if (this.req.url === '/') {
      this.serveFile('index.html');
    } else if (this.req.url === '/log.html') {
      this.checkAndGenerateReport();
      this.serveFile('log.html');
    } else if (this.req.url === '/chat.html') {
      this.checkAndGenerateChatHtml();
      this.serveFile('chat.html');
    } else if (this.req.url === '/api/github_update') {
      this.handleGithubUpdate();
    } else if (this.req.url.endsWith('.txt')) {
      this.serveTextFile();
    } else {
      this.serveFile(this.req.url.slice(1));
    }
  }

  handlePost() {
    if (this.req.url === '/chat.html') {
      this.handleChatPost();
    } else {
      this.sendError(405, "Method Not Allowed");
    }
  }

  handleChatPost() {
    let body = '';
    this.req.on('data', chunk => {
      body += chunk.toString();
    });
    this.req.on('end', () => {
      const params = querystring.parse(body);
      const author = params.author || '';
      const message = params.message || '';

      if (author && message) {
        this.saveMessage(author, message);
        this.res.writeHead(200, { 'Content-Type': 'text/html' });
        this.res.end("Message saved successfully" + '<meta http-equiv="refresh" content="1;url=chat.html">');

        // Commit the message and update GitHub
        exec('python3 commit_files.py message', (error, stdout, stderr) => {
          if (error) console.error(`Error: ${error.message}`);
          if (stderr) console.error(`Error: ${stderr}`);
          console.log(`Output: ${stdout}`);

          exec('python3 github_update.py', (error, stdout, stderr) => {
            if (error) console.error(`Error: ${error.message}`);
            if (stderr) console.error(`Error: ${stderr}`);
            console.log(`Output: ${stdout}`);
          });
        });
      } else {
        this.sendError(400, "Bad Request: Missing author or message");
      }
    });
  }

  saveMessage(author, message) {
    const today = DateTime.now().toFormat('yyyy-MM-dd');
    const directory = path.join(this.directory, 'message', today);
    fs.mkdirSync(directory, { recursive: true });

    const title = this.generateTitle(message);
    const filename = `${title}.txt`;
    const filepath = path.join(directory, filename);

    fs.writeFileSync(filepath, `${message}\n\nauthor: ${author}`, 'utf-8');
  }

  generateTitle(message) {
    let title = message.split(' ').slice(0, 5).join('_');
    title = title.replace(/[^a-zA-Z0-9_-]/g, '');
    if (!title) {
      title = Math.random().toString(36).substring(2, 12);
    }
    return title;
  }

  handleGithubUpdate() {
    this.res.writeHead(200, { 'Content-Type': 'text/html' });
    this.res.end("Update triggered successfully");
    exec('python3 github_update.py', (error, stdout, stderr) => {
      if (error) console.error(`Error: ${error.message}`);
      if (stderr) console.error(`Error: ${stderr}`);
      console.log(`Output: ${stdout}`);
    });
  }

  checkAndGenerateReport() {
    const htmlFile = path.join(this.directory, 'log.html');
    fs.stat(htmlFile, (err, stats) => {
      if (err || Date.now() - stats.mtime.getTime() > 60000) {
        console.log(`${htmlFile} is older than 60 seconds or does not exist. Running log.html.js...`);
        exec('python3 log.html.py', (error, stdout, stderr) => {
          if (error) console.error(`Error: ${error.message}`);
          if (stderr) console.error(`Error: ${stderr}`);
          console.log(`Output: ${stdout}`);
        });
      } else {
        console.log(`${htmlFile} is up-to-date.`);
      }
    });
  }

  checkAndGenerateChatHtml() {
    const chatHtmlFile = path.join(this.directory, 'chat.html');
    fs.stat(chatHtmlFile, (err, stats) => {
      if (err || Date.now() - stats.mtime.getTime() > 60000) {
        console.log(`${chatHtmlFile} is older than 60 seconds or does not exist. Running chat.html.py...`);
        exec('python3 chat.html.py', (error, stdout, stderr) => {
          if (error) console.error(`Error: ${error.message}`);
          if (stderr) console.error(`Error: ${stderr}`);
          console.log(`Output: ${stdout}`);
        });
      } else {
        console.log(`${chatHtmlFile} is up-to-date.`);
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

function isPortInUse(port) {
  return new Promise((resolve) => {
    const server = http.createServer();
    server.once('error', () => {
      resolve(true);
    });
    server.once('listening', () => {
      server.close();
      resolve(false);
    });
    server.listen(port);
  });
}

async function findAvailablePort(startPort) {
  let port = startPort;
  while (await isPortInUse(port)) {
    port++;
  }
  return port;
}

async function runServer(port, directory) {
  process.chdir(directory);
  const server = http.createServer((req, res) => {
    const handler = new CustomHTTPRequestHandler(req, res);
    handler.handleRequest();
  });

  try {
    await new Promise((resolve, reject) => {
      server.listen(port, () => {
        console.log(`Serving HTTP on 0.0.0.0 port ${port} (http://0.0.0.0:${port}/) ...`);
        resolve();
      });
      server.on('error', reject);
    });
    return true;
  } catch (error) {
    if (error.code === 'EADDRINUSE') {
      console.log(`Port ${port} is already in use.`);
      return false;
    }
    throw error;
  }
}

function parseArguments() {
  const args = process.argv.slice(2);
  let port;
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

async function main() {
  const { port: specifiedPort, directory } = parseArguments();

  if (specifiedPort) {
    if (!await runServer(specifiedPort, directory)) {
      console.log(`Failed to start server on specified port ${specifiedPort}.`);
    }
  } else {
    let port = 8000;
    while (!await runServer(port, directory)) {
      port = await findAvailablePort(port + 1);
      console.log(`Trying port ${port}...`);
    }
  }
}

main().catch(console.error);

// end of start_server.js