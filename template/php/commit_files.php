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
	$currDir = getcwd();
	$repoPath = realpath($repoPath);
	chdir($repoPath);

	try {
		// Get modified and untracked files
		exec("git diff --name-only", $changedFiles);
		exec("git ls-files --others --exclude-standard", $untrackedFiles);

		$allFiles = array_merge($changedFiles, $untrackedFiles);
		$txtFiles = array_filter($allFiles, function($file) {
			return substr($file, -4) === '.txt';
		});

		if (empty($txtFiles)) {
			echo "No uncommitted .txt files found.\n";
			return;
		}

		foreach ($txtFiles as $filePath) {
			try {
				$absPath = $repoPath . DIRECTORY_SEPARATOR . $filePath;
				$content = file_get_contents($absPath);
				$metadata = extractMetadata($content, $absPath);
				$metadataFile = storeMetadata($absPath, $metadata);

				echo "File: " . basename($filePath) . "\n";
				echo "Author: {$metadata['author']}\n";
				echo "Title: {$metadata['title']}\n";
				echo "Hashtags: " . implode(', ', $metadata['hashtags']) . "\n";
				echo "File Hash: {$metadata['file_hash']}\n\n";

				exec("git add " . escapeshellarg($filePath) . " " . escapeshellarg(str_replace($repoPath . DIRECTORY_SEPARATOR, '', $metadataFile)));
			} catch (Exception $e) {
				echo "Error processing file $filePath: {$e->getMessage()}\n";
			}
		}

		// Create commit
		$timestamp = date('Y-m-d H:i:s');
		$commitMessage = "Auto-commit " . count($txtFiles) . " text files and metadata on " . $timestamp . " by commit_files.php";
		exec("git commit -m " . escapeshellarg($commitMessage));

		echo "Committed " . count($txtFiles) . " text files and their metadata.\n";
		echo "Commit message: $commitMessage\n";
	} finally {
		chdir($currDir);
	}
}

if (php_sapi_name() === 'cli') {
	commitTextFiles();
}

?>