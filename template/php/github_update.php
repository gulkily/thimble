<?php
// github_update.php
// to run: php github_update.php [--debug]

$DEBUG = false;

function debug_print($message) {
	global $DEBUG;
	if ($DEBUG) {
		echo "DEBUG: $message\n";
	}
}

function run_git_command($command) {
	debug_print("Running command: $command");
	$output = [];
	$return_var = 0;
	exec($command . " 2>&1", $output, $return_var);
	$output_str = implode("\n", $output);
	debug_print("Command output: $output_str");
	return [$output_str, $return_var];
}

function check_for_uncommitted_changes() {
	echo "Checking for uncommitted changes...\n";
	list($status_output, $return_var) = run_git_command("git status --porcelain");
	if ($status_output) {
		echo "Uncommitted changes found.\n";
	} else {
		echo "No uncommitted changes.\n";
	}
	return !empty($status_output);
}

function stash_changes() {
	echo "Stashing local changes...\n";
	list($output, $return_var) = run_git_command("git stash");
	if (strpos($output, "No local changes to save") !== false) {
		echo "No changes to stash.\n";
	} elseif ($return_var !== 0) {
		echo "Error stashing changes: $output\n";
		exit(1);
	} else {
		echo "Changes stashed successfully.\n";
	}
}

function pop_stashed_changes() {
	echo "Applying stashed changes...\n";
	list($output, $return_var) = run_git_command("git stash pop");
	if (strpos($output, "No stash entries found") !== false) {
		echo "No stashed changes to apply.\n";
	} elseif ($return_var !== 0 && strpos($output, "CONFLICT") === false) {
		echo "Error applying stashed changes: $output\n";
		exit(1);
	} elseif (strpos($output, "CONFLICT") !== false) {
		echo "Conflicts occurred while applying stashed changes. Please resolve manually.\n";
	} else {
		echo "Stashed changes applied successfully.\n";
	}
}

function fetch_remote() {
	echo "Fetching remote changes...\n";
	list($output, $return_var) = run_git_command("git fetch");
	if ($return_var !== 0) {
		echo "Error fetching remote: $output\n";
		exit(1);
	}
	echo "Remote changes fetched successfully.\n";
}

function check_for_diverged_history() {
	echo "Checking for diverged history...\n";
	list($local_commit, $return_var) = run_git_command("git rev-parse HEAD");
	list($remote_commit, $return_var) = run_git_command("git rev-parse @{u}");
	$diverged = trim($local_commit) !== trim($remote_commit);
	if ($diverged) {
		echo "Local and remote histories have diverged.\n";
	} else {
		echo "Local and remote histories are in sync.\n";
	}
	return $diverged;
}

function merge_remote_changes() {
	echo "Merging remote changes...\n";
	list($output, $return_var) = run_git_command("git merge origin/main");
	if (strpos($output, "CONFLICT") !== false) {
		echo "Merge conflict detected. Please resolve conflicts manually.\n";
		exit(1);
	} elseif ($return_var !== 0) {
		echo "Error merging changes: $output\n";
		exit(1);
	} else {
		echo "Remote changes merged successfully.\n";
	}
}

function push_changes() {
	echo "Pushing local changes to remote...\n";
	list($output, $return_var) = run_git_command("git push");
	if ($return_var !== 0) {
		echo "Error pushing changes: $output\n";
		exit(1);
	}
	echo "Local changes pushed successfully.\n";
}

function github_update() {
	// Check for uncommitted changes
	if (check_for_uncommitted_changes()) {
		stash_changes();
		$stashed = true;
	} else {
		$stashed = false;
	}

	// Fetch remote changes
	fetch_remote();

	// Check for diverged history
	if (check_for_diverged_history()) {
		merge_remote_changes();
	}

	// Push local changes
	push_changes();

	// Apply stashed changes if any
	if ($stashed) {
		pop_stashed_changes();
	}

	echo "GitHub repository updated successfully.\n";
}

// Parse command line arguments
$options = getopt("", ["debug"]);
$DEBUG = isset($options["debug"]);

github_update();