<?php

# test_log.html.php
# to run: php test_log.html.php
function run_generate_report($script) {
	$start_time = microtime(true);
	exec($script . " 2>&1", $output, $return_code);
	$end_time = microtime(true);
	return array($return_code, implode("\n", $output), $end_time - $start_time);
}

function check_output_file($file_path) {
	return file_exists($file_path) && filesize($file_path) > 0;
}

$scripts = array(
	'python3 log.html.py',
	'php log.html.php',
	'node log.html.js',
	'bash log.html.sh'
);

foreach ($scripts as $script) {
	echo "\nTesting: $script\n";

	// Run the script
	list($return_code, $output, $execution_time) = run_generate_report($script);

	// Check return code
	assert($return_code === 0, "Script failed with return code $return_code");
	echo "Script executed successfully\n";

	// Check execution time
	assert($execution_time < 60, "Script took too long to execute: " . number_format($execution_time, 2) . " seconds");
	echo "Execution time: " . number_format($execution_time, 2) . " seconds\n";

	// Check if output file exists and is not empty
	assert(check_output_file('log.html'), "Output file 'log.html' is missing or empty");
	echo "Output file 'log.html' generated successfully\n";

	// Clean up
	unlink('log.html');
}

echo "\nAll tests passed successfully!\n";

# end of test_log.html.php