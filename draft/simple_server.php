<?php

if (php_sapi_name() !== 'cli-server') {
	die("This script is meant to be run from PHP's built-in web server");
}

$uri = $_SERVER['REQUEST_URI'];

if ($uri == '/' || $uri == '') {
	echo "Hello, World! The server is working.";
} else {
	$path = __DIR__ . $uri;
	if (is_file($path)) {
		return false; // Serve the requested file
	} else {
		echo "404 Not Found";
	}
}
