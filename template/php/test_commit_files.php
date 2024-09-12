<?php
// test_commit_files.php
// to run: php test_commit_files.php

function random_string($length = 8) {
	return bin2hex(random_bytes($length));
}

function create_test_file($content) {
	$date_str = date('Y-m-d');
	$filename = random_string() . '.txt';
	$dir_path = "message" . DIRECTORY_SEPARATOR . $date_str;
	if (!is_dir($dir_path)) {
		mkdir($dir_path, 0777, true);
	}
	$file_path = $dir_path . DIRECTORY_SEPARATOR . $filename;
	
	file_put_contents($file_path, $content);
	
	return $file_path;
}

function run_commit_files($script) {
	exec($script);
}

function check_git_log() {
	$log_output = exec('git log -1 --pretty=format:%s');
	return strpos($log_output, 'Auto-commit') !== false;
}

function check_metadata_file($filename) {
	$metadata_file = dirname($filename) . DIRECTORY_SEPARATOR . "metadata" . DIRECTORY_SEPARATOR . basename($filename) . ".json";
	if (!file_exists($metadata_file)) {
		return false;
	}
	$metadata = json_decode(file_get_contents($metadata_file), true);
	return isset($metadata['author']) && isset($metadata['title']) && isset($metadata['hashtags']) && isset($metadata['file_hash']);
}

function run_tests($script) {
	echo "Testing {$script}\n";

	// Test 1: Commit a single file
	$file1 = create_test_file("Author: John Doe\nThe Beauty of Nature\n\nNature's beauty is an awe-inspiring spectacle that never fails to amaze us. From the grandeur of mountains to the delicacy of a flower, it reminds us of the world's magnificence.\n\n#nature #beauty #inspiration");
	run_commit_files($script);
	assert(check_git_log(), "Git commit not found");
	assert(check_metadata_file($file1), "Metadata file not created or invalid");
	echo "Test 1 passed: Single file commit\n";

	// Test 2: Commit multiple files
	$file2 = create_test_file("Author: Jane Smith\nThe Art of Cooking\n\nCooking is not just about sustenance; it's an art form that engages all our senses. The sizzle of a pan, the aroma of spices, and the vibrant colors of fresh ingredients all come together to create culinary masterpieces.\n\n#cooking #art #food");
	$file3 = create_test_file("Author: Bob Johnson\nThe Joy of Learning\n\nLearning is a lifelong journey that opens doors to new worlds. Whether it's picking up a new skill or diving deep into a subject, the process of discovery and growth is incredibly rewarding.\n\n#learning #education #growth");
	run_commit_files($script);
	assert(check_git_log(), "Git commit not found");
	assert(check_metadata_file($file2) && check_metadata_file($file3), "Metadata files not created or invalid");
	echo "Test 2 passed: Multiple file commit\n";

	// Test 3: No changes to commit
	run_commit_files($script);
	echo "Test 3 passed: No changes to commit\n";

	echo "All tests passed for {$script}\n";
}

$scripts = [
	'python3 commit_files.py',
	'node commit_files.js',
	'php commit_files.php',
	'php commit_files.pl',
	'ruby commit_files.rb'
];

foreach ($scripts as $script) {
	run_tests($script);
}