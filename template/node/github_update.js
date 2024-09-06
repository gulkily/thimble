#!/usr/bin/env node
// github_update.js
// to run: node github_update.js [--debug]

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

let DEBUG = false;

function debugPrint(message) {
    if (DEBUG) {
        console.log(`DEBUG: ${message}`);
    }
}

function runGitCommand(command) {
    debugPrint(`Running command: ${command}`);
    try {
        const output = execSync(command, { encoding: 'utf-8' }).trim();
        debugPrint(`Command output: ${output}`);
        return { output, error: null };
    } catch (error) {
        debugPrint(`Command error: ${error.stderr}`);
        return { output: null, error: error.stderr };
    }
}

function checkForUncommittedChanges() {
    console.log("Checking for uncommitted changes...");
    const { output } = runGitCommand("git status --porcelain");
    if (output) {
        console.log("Uncommitted changes found.");
    } else {
        console.log("No uncommitted changes.");
    }
    return Boolean(output);
}

function stashChanges() {
    console.log("Stashing local changes...");
    const { output, error } = runGitCommand("git stash");
    if (output.includes("No local changes to save")) {
        console.log("No changes to stash.");
    } else if (error) {
        console.log(`Error stashing changes: ${error}`);
        process.exit(1);
    } else {
        console.log("Changes stashed successfully.");
    }
}

function popStashedChanges() {
    console.log("Applying stashed changes...");
    const { output, error } = runGitCommand("git stash pop");
    if (error && error.includes("No stash entries found")) {
        console.log("No stashed changes to apply.");
    } else if (error && !error.includes("CONFLICT")) {
        console.log(`Error applying stashed changes: ${error}`);
        process.exit(1);
    } else if (error && error.includes("CONFLICT")) {
        console.log("Conflicts occurred while applying stashed changes. Please resolve manually.");
    } else {
        console.log("Stashed changes applied successfully.");
    }
}

function fetchRemote() {
    console.log("Fetching remote changes...");
    const { error } = runGitCommand("git fetch");
    if (error) {
        console.log(`Error fetching remote: ${error}`);
        process.exit(1);
    }
    console.log("Remote changes fetched successfully.");
}

function checkForDivergedHistory() {
    console.log("Checking for diverged history...");
    const { output: localCommit } = runGitCommand("git rev-parse HEAD");
    const { output: remoteCommit } = runGitCommand("git rev-parse @{u}");
    const diverged = localCommit !== remoteCommit;
    if (diverged) {
        console.log("Local and remote histories have diverged.");
    } else {
        console.log("Local and remote histories are in sync.");
    }
    return diverged;
}

function mergeRemoteChanges() {
    console.log("Merging remote changes...");
    const { output, error } = runGitCommand("git merge origin/main");
    if (output.includes("CONFLICT") || (error && error.includes("CONFLICT"))) {
        console.log("Merge conflict detected. Please resolve conflicts manually.");
        process.exit(1);
    } else if (error) {
        console.log(`Error merging changes: ${error}`);
        process.exit(1);
    } else {
        console.log("Remote changes merged successfully.");
    }
}

function pushChanges() {
    console.log("Pushing local changes to remote...");
    const { error } = runGitCommand("git push");
    if (error) {
        console.log(`Error pushing changes: ${error}`);
        process.exit(1);
    }
    console.log("Local changes pushed successfully.");
}

function updateGithub() {
    // Check for uncommitted changes
    const stashed = checkForUncommittedChanges();
    if (stashed) {
        stashChanges();
    }

    // Fetch remote changes
    fetchRemote();

    // Check for diverged history
    if (checkForDivergedHistory()) {
        mergeRemoteChanges();
    }

    // Push local changes
    pushChanges();

    // Apply stashed changes if any
    if (stashed) {
        popStashedChanges();
    }

    console.log("GitHub repository updated successfully.");
}

if (require.main === module) {
    const args = process.argv.slice(2);
    DEBUG = args.includes("--debug");

    updateGithub();
}
