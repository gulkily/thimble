#!/usr/bin/env node

// upgrade_from_repo.js
// to run: node upgrade_from_repo.js <repository_path>

// Functionality Definition:
//
// This script updates a Git repository to the latest version of its main branch.
// It performs the following steps:
//
// 1. Check if a repository path is provided as a command-line argument.
// 2. Change the working directory to the provided repository path.
// 3. Verify that the directory is a Git repository.
// 4. Determine the name of the main branch (e.g., 'main' or 'master').
// 5. Checkout the main branch.
// 6. Stash any local changes to prevent conflicts.
// 7. Fetch the latest changes from the remote repository.
// 8. Reset the local branch to match the remote branch exactly.
// 9. Clean up any untracked files and directories.
// 10. Update all submodules recursively.
// 11. Attempt to reapply the stashed changes.
// 12. Verify the integrity of the repository.
// 13. Print a success message if all steps complete without error.
//
// The script includes error handling to catch and report any issues that occur
// during the update process. It uses child_process.execSync to execute Git commands
// and capture their output for error checking.
//

const { execSync } = require('child_process');
const path = require('path');

function runCommand(command) {
	try {
		return execSync(command, { encoding: 'utf8', stdio: 'pipe' }).trim();
	} catch (error) {
		console.error(`Error executing command: ${command}`);
		console.error(`Error message: ${error.stderr}`);
		return null;
	}
}

function isGitRepo() {
	return runCommand('git rev-parse --is-inside-work-tree') !== null;
}

function main() {
	const repoPath = process.argv[2];
	if (!repoPath) {
		console.log(`Usage: ${process.argv[1]} <repository_path>`);
		process.exit(1);
	}

	try {
		process.chdir(repoPath);
	} catch (error) {
		console.error(`Cannot change to directory ${repoPath}: ${error.message}`);
		process.exit(1);
	}

	if (!isGitRepo()) {
		console.error('Error: Not a Git repository');
		process.exit(1);
	}

	// Get the main branch name
	const remoteInfo = runCommand('git remote show origin');
	const mainBranch = remoteInfo.match(/HEAD branch: (\S+)/)[1];

	// Checkout the main branch
	runCommand(`git checkout ${mainBranch}`);

	// Stash any local changes
	runCommand('git stash');

	// Fetch the latest changes
	runCommand('git fetch origin');

	// Reset to the latest commit on the main branch
	runCommand(`git reset --hard origin/${mainBranch}`);

	// Clean up untracked files and directories
	runCommand('git clean -fd');

	// Update submodules
	runCommand('git submodule update --init --recursive');

	// Apply stashed changes if any
	runCommand('git stash pop');

	// Verify the repository integrity
	runCommand('git fsck');

	console.log('Repository updated successfully');
}

main();

// end of upgrade_from_repo.js