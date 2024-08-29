<?php
// test_start_server.php v2
// to run: php test_start_server.php

function port_status($port = 8000) {
	// checks whether port 8000 is listening
	exec("netstat -tulnp 2>/dev/null | grep $port", $output, $return_var);
	return $return_var === 0;
}

function start_server($script) {
	// start the server, forked
	$descriptorspec = array(
		0 => array("pipe", "r"),
		1 => array("pipe", "w"),
		2 => array("pipe", "w")
	);
	$process = proc_open($script, $descriptorspec, $pipes);
	sleep(2);
	return $process;
}

function stop_server($process) {
	// stop the server
	$status = proc_get_status($process);
	if ($status['running']) {
		proc_terminate($process);
		proc_close($process);
	}
}

// SETUP:

// check for listening on port 8000 (should be false):
assert(!port_status(), "Port 8000 is already in use");

echo "PASS: SETUP\n";

// TESTS:

$server_scripts = [
	'python3 start_server.py',
	'ruby start_server.rb',
	'php start_server.php',
	'node start_server.js',
	'perl start_server.pl'
];

foreach ($server_scripts as $script) {
	echo "\nTesting: $script\n";

	// Start the server
	$server_process = start_server($script);

	// Verify that the server is listening on port 8000
	assert(port_status(), "Server failed to start: $script");
	echo "Server started successfully\n";

	// Stop the server
	stop_server($server_process);

	// Verify that the server is no longer listening
	assert(!port_status(), "Server failed to stop: $script");
	echo "Server stopped successfully\n";
}

echo "\nAll tests passed successfully!\n";

# end of test_start_server.php