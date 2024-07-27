<?php

class CustomHTTPRequestHandler {
    private $directory;

    public function __construct($directory = null) {
        $this->directory = $directory ?: getcwd();
    }

    public function handleRequest($uri) {
        if ($uri == '/' || $uri == '') {
            $this->checkAndGenerateReport();
            $this->serveFile('/index.html');
        } elseif (substr($uri, -4) === '.txt') {
            $this->serveTextFile($uri);
        } else {
            $this->serveFile($uri);
        }
    }

    private function checkAndGenerateReport() {
        $reportFile = $this->directory . '/report.txt';
        if (!file_exists($reportFile) || (time() - filemtime($reportFile)) > 3600) {
            $this->generateReport();
        }
    }

    private function generateReport() {
        $reportContent = "Report generated at: " . date('Y-m-d H:i:s') . "\n\n";
        $reportContent .= "Files in directory:\n";

        $files = scandir($this->directory);
        foreach ($files as $file) {
            if ($file != '.' && $file != '..') {
                $reportContent .= "- $file\n";
            }
        }

        file_put_contents($this->directory . '/report.txt', $reportContent);
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
            header("Content-Type: text/plain");
            readfile($filePath);
        } else {
            $this->sendNotFound();
        }
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
$port = 8000;
$directory = getcwd();

$options = getopt("p:d:", ["port:", "directory:"]);
if (isset($options['p'])) $port = $options['p'];
if (isset($options['port'])) $port = $options['port'];
if (isset($options['d'])) $directory = $options['d'];
if (isset($options['directory'])) $directory = $options['directory'];

// Run the server
runServer($port, $directory);

// Handle incoming requests
if (php_sapi_name() === 'cli-server') {
    $handler = new CustomHTTPRequestHandler($directory);
    $handler->handleRequest($_SERVER['REQUEST_URI']);
}