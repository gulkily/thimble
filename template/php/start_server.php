<?php

# start_server.php
# to run: php start_server.php

# start_server: v3

class CustomHTTPRequestHandler {
	private $directory;

	public function __construct($directory = null) {
		$this->directory = $directory ?: getcwd();
	}

	public function handleRequest($uri, $method) {
		if ($uri == '/' || $uri == '') {
			$this->serveFile('/index.html');
		} elseif ($uri == '/log.html') {
			$this->checkAndGenerateReport();
			$this->serveFile('/log.html');
		} elseif ($uri == '/chat.html') {
			$this->checkAndGenerateChatHtml();
			$this->serveFile('/chat.html');
		} elseif ($uri == '/api/github_update') {
			$this->triggerGithubUpdate();
		} elseif (substr($uri, -4) === '.txt') {
			$this->serveTextFile($uri);
		} elseif ($method === 'POST' && $uri == '/chat.html') {
			$this->handleChatPost();
		} else {
			$this->serveFile($uri);
		}
	}

	private function checkAndGenerateReport() {
		$htmlFile = $this->directory . '/log.html';
		if (!file_exists($htmlFile) || (time() - filemtime($htmlFile)) > 60) {
			echo "log.html is older than 60 seconds or does not exist. Running log.html.py...\n";
			exec('python log.html.py');
		} else {
			echo "log.html is up-to-date.\n";
		}
	}

	private function checkAndGenerateChatHtml() {
		$chatHtmlFile = $this->directory . '/chat.html';
		if (!file_exists($chatHtmlFile) || (time() - filemtime($chatHtmlFile)) > 60) {
			echo "chat.html is older than 60 seconds or does not exist. Running chat.html.py...\n";
			exec('python chat.html.py');
		} else {
			echo "chat.html is up-to-date.\n";
		}
	}

	private function triggerGithubUpdate() {
		header('Content-Type: text/html');
		echo "Update triggered successfully";
		exec('python github_update.py');
	}

	private function handleChatPost() {
		$author = $_POST['author'] ?? '';
		$message = $_POST['message'] ?? '';

		if ($author && $message) {
			$this->saveMessage($author, $message);
			header('Content-Type: text/html');
			echo "Message saved successfully";
			echo '<meta http-equiv="refresh" content="1;url=/chat.html">';
			exec('python commit_files.py message');
			exec('python github_update.py');
		} else {
			header("HTTP/1.0 400 Bad Request");
			echo "Bad Request: Missing author or message";
		}
	}

	private function saveMessage($author, $message) {
		$today = date('Y-m-d');
		$directory = $this->directory . "/message/$today";
		if (!is_dir($directory)) {
			mkdir($directory, 0777, true);
		}

		$title = $this->generateTitle($message);
		$filename = "$title.txt";
		$filepath = "$directory/$filename";

		file_put_contents($filepath, $message . "\n\nauthor: $author");
	}

	private function generateTitle($message) {
		$words = array_slice(explode(' ', $message), 0, 5);
		$title = implode('_', $words);
		$title = preg_replace('/[^a-zA-Z0-9_-]/', '', $title);
		if (empty($title)) {
			$title = substr(str_shuffle('abcdefghijklmnopqrstuvwxyz'), 0, 10);
		}
		return $title;
	}

	private function serveFile($uri) {
		$filePath = $this->directory . $uri;
		if (file_exists($filePath) && !is_dir($filePath)) {
			$mimeType = $this->getMimeType($filePath);
			header("Content-Type: $mimeType");
			readfile($filePath);
		} else {
			$this->sendNotFound();
		}
	}

	private function serveTextFile($uri) {
		$filePath = $this->directory . $uri;
		if (file_exists($filePath) && !is_dir($filePath)) {
			$content = file_get_contents($filePath);
			$htmlContent = $this->generateHtmlForTextFile(basename($filePath), $content);
			header("Content-Type: text/html; charset=utf-8");
			echo $htmlContent;
		} else {
			$this->sendNotFound();
		}
	}

	private function generateHtmlForTextFile($filename, $content) {
		$escapedContent = htmlspecialchars($content);
		return <<<HTML
	<!DOCTYPE html>
	<html lang="en">
	<head>
	    <meta charset="UTF-8">
	    <meta name="viewport" content="width=device-width, initial-scale=1.0">
	    <title>$filename</title>
	    <style>
		body { font-family: Arial, sans-serif; line-height: 1.6; padding: 20px; }
		pre { background-color: #f4f4f4; padding: 15px; border-radius: 5px; white-space: pre-wrap; word-wrap: break-word; }
	    </style>
	</head>
	<body>
	    <h1>$filename</h1>
	    <pre>$escapedContent</pre>
	</body>
	</html>
	HTML;
	}

	private function sendNotFound() {
		header("HTTP/1.0 404 Not Found");
		echo "404 Not Found";
	}

	private function getMimeType($filePath) {
		$mimeTypes = [
			'txt' => 'text/plain',
			'html' => 'text/html',
			'css' => 'text/css',
			'js' => 'application/javascript',
			'json' => 'application/json',
			'png' => 'image/png',
			'jpg' => 'image/jpeg',
			'gif' => 'image/gif',
		];

		$extension = strtolower(pathinfo($filePath, PATHINFO_EXTENSION));
		return isset($mimeTypes[$extension]) ? $mimeTypes[$extension] : 'application/octet-stream';
	}
}

function isPortInUse($port) {
	$connection = @fsockopen('localhost', $port);
	if (is_resource($connection)) {
		fclose($connection);
		return true;
	}
	return false;
}

function findAvailablePort($startPort) {
	$port = $startPort;
	while (isPortInUse($port)) {
		$port++;
	}
	return $port;
}

function runServer($port, $directory) {
	$host = '0.0.0.0';
	echo "Starting server on http://$host:$port\n";
	echo "Serving directory: $directory\n";

	$command = sprintf(
		'php -S %s:%d -t %s %s',
		$host,
		$port,
		escapeshellarg($directory),
		escapeshellarg(__FILE__)
	);

	passthru($command);
}

// Parse command line arguments
$options = getopt("p:d:", ["port:", "directory:"]);
$port = $options['p'] ?? $options['port'] ?? null;
$directory = $options['d'] ?? $options['directory'] ?? getcwd();

if ($port === null) {
	$port = 8000;
	while (isPortInUse($port)) {
		$port = findAvailablePort($port + 1);
		echo "Trying port $port...\n";
	}
} elseif (isPortInUse($port)) {
	echo "Port $port is already in use.\n";
	exit(1);
}

// Run the server
runServer($port, $directory);

// Handle incoming requests
if (php_sapi_name() === 'cli-server') {
	$handler = new CustomHTTPRequestHandler($directory);
	$handler->handleRequest($_SERVER['REQUEST_URI'], $_SERVER['REQUEST_METHOD']);
}

# end of start_server.php