<?php

# commit_files.php
# to run: php commit_files.php  

function calculateFileHash($filePath) {
	return hash_file('sha256', $filePath);
}

function extractMetadata($content, $filePath) {
	$metadata = [
		'author' => '',
		'title' => basename($filePath),
		'hashtags' => [],
		'file_hash' => calculateFileHash($filePath)
	];

	// Extract author
	if (preg_match('/Author:\s*(.+)/', $content, $matches)) {
		$metadata['author'] = $matches[1];
	}

	// Extract title (assuming it's the first line of the file)
	if (preg_match('/^(.+)/', $content, $matches)) {
		$metadata['title'] = trim($matches[1]);
	}

	// Extract hashtags
	preg_match_all('/#\w+/', $content, $matches);
	$metadata['hashtags'] = $matches[0];

	return $metadata;
}

function storeMetadata($filePath, $metadata) {
	$metadataDir = dirname($filePath) . DIRECTORY_SEPARATOR . 'metadata';
	if (!is_dir($metadataDir)) {
		mkdir($metadataDir, 0777, true);
	}

	$metadataFile = $metadataDir . DIRECTORY_SEPARATOR . basename($filePath) . '.json';
	file_put_contents($metadataFile, json_encode($metadata, JSON_PRETTY_PRINT));

	return $metadataFile;
}

function commitTextFiles($repoPath = ".") {
	// Check if it's a valid Git repository
	if (!is_dir($repoPath . DIRECTORY_SEPARATOR . '.git')) {
		echo "Error: $repoPath is not a valid Git repository.\n";
		return;
	}

	// Get modified and untracked files
	exec("git -C " . escapeshellarg($repoPath) . " status --porcelain", $output);
	$changedFiles = array_filter($output, function($line) {
		return preg_match('/^(\s[MD]|\?\?)\s.*\.txt$/', $line);
	});

	if (empty($changedFiles)) {
		echo "No uncommitted .txt files found.\n";
		return;
	}

	$metadataFiles = [];

	foreach ($changedFiles as $file) {
		$filePath = $repoPath . DIRECTORY_SEPARATOR . trim(substr($file, 3));

		try {
			$content = file_get_contents($filePath);
			$metadata = extractMetadata($content, $filePath);
			$metadataFile = storeMetadata($filePath, $metadata);
			$metadataFiles[] = $metadataFile;

			echo "File: " . basename($filePath) . "\n";
			echo "Author: {$metadata['author']}\n";
			echo "Title: {$metadata['title']}\n";
			echo "Hashtags: " . implode(', ', $metadata['hashtags']) . "\n";
			echo "File Hash: {$metadata['file_hash']}\n\n";
		} catch (Exception $e) {
			echo "Error processing file $filePath: {$e->getMessage()}\n";
		}
	}

	// Add all changed .txt files and metadata files to staging
	$filesToAdd = array_merge(
		array_map(function($file) { return escapeshellarg(trim(substr($file, 3))); }, $changedFiles),
		array_map('escapeshellarg', $metadataFiles)
	);
	exec("git -C " . escapeshellarg($repoPath) . " add " . implode(' ', $filesToAdd));

	// Create commit message
	$commitMessage = "Auto-commit " . count($changedFiles) . " text files and metadata on " . date('Y-m-d H:i:s') . " by commit_files.php";

	// Commit the changes
	exec("git -C " . escapeshellarg($repoPath) . " commit -m " . escapeshellarg($commitMessage));

	echo "Committed " . count($changedFiles) . " text files and their metadata.\n";
	echo "Commit message: $commitMessage\n";
}

if (php_sapi_name() === 'cli') {
	commitTextFiles();
}

?>