// commit_files.js
// to run: node commit_files.js

const fs = require('fs').promises;
const path = require('path');
const crypto = require('crypto');
const { execSync } = require('child_process');

async function calculateFileHash(filePath) {
	const fileBuffer = await fs.readFile(filePath);
	const hashSum = crypto.createHash('sha256');
	hashSum.update(fileBuffer);
	return hashSum.digest('hex');
}

async function extractMetadata(content, filePath) {
	const metadata = {
		author: '',
		title: path.basename(filePath),
		hashtags: [],
		file_hash: await calculateFileHash(filePath)
	};

	// Extract author
	const authorMatch = content.match(/Author:\s*(.+)/);
	if (authorMatch) {
		metadata.author = authorMatch[1];
	}

	// Extract title (assuming it's the first line of the file)
	const titleMatch = content.match(/^(.+)/);
	if (titleMatch) {
		metadata.title = titleMatch[1].trim();
	}

	// Extract hashtags
	metadata.hashtags = content.match(/#\w+/g) || [];

	return metadata;
}

async function storeMetadata(filePath, metadata) {
	const metadataDir = path.join(path.dirname(filePath), 'metadata');
	await fs.mkdir(metadataDir, { recursive: true });

	const metadataFile = path.join(metadataDir, `${path.basename(filePath)}.json`);

	await fs.writeFile(metadataFile, JSON.stringify(metadata, null, 2), 'utf-8');

	return metadataFile;
}

function gitCommand(command) {
	try {
		return execSync(command, { encoding: 'utf-8' }).trim();
	} catch (error) {
		console.error(`Error executing Git command: ${error.message}`);
		return '';
	}
}

async function commitTextFiles(repoPath = '.') {
	const currDir = process.cwd();
	repoPath = path.resolve(repoPath);
	process.chdir(repoPath);

	try {
		// Get modified and untracked files
		const changedFiles = gitCommand('git diff --name-only').split('\n').filter(Boolean);
		const untrackedFiles = gitCommand('git ls-files --others --exclude-standard').split('\n').filter(Boolean);

		const allFiles = [...changedFiles, ...untrackedFiles];
		const txtFiles = allFiles.filter(f => f.endsWith('.txt'));

		if (!txtFiles.length) {
			console.log("No uncommitted .txt files found.");
			return;
		}

		for (const filePath of txtFiles) {
			try {
				const absPath = path.join(repoPath, filePath);
				const content = await fs.readFile(absPath, 'utf-8');
				const metadata = await extractMetadata(content, absPath);
				const metadataFile = await storeMetadata(absPath, metadata);

				console.log(`File: ${filePath}`);
				console.log(`Author: ${metadata.author}`);
				console.log(`Title: ${metadata.title}`);
				console.log(`Hashtags: ${metadata.hashtags.join(', ')}`);
				console.log(`File Hash: ${metadata.file_hash}`);
				console.log();

				gitCommand(`git add '${filePath}' '${path.relative(repoPath, metadataFile)}'`);
			} catch (e) {
				console.error(`Error processing file ${filePath}: ${e.message}`);
			}
		}

		// Create commit
		const timestamp = new Date().toISOString().replace('T', ' ').split('.')[0];
		const commitMessage = `Auto-commit ${txtFiles.length} text files and metadata on ${timestamp} by commit_files.js`;
		gitCommand(`git commit -m '${commitMessage}'`);

		console.log(`Committed ${txtFiles.length} text files and their metadata.`);
		console.log(`Commit message: ${commitMessage}`);
	} finally {
		process.chdir(currDir);
	}
}

if (require.main === module) {
	const repo_path = (process.argv.length >= 3) ? process.argv[2] : "."
	commitTextFiles(repo_path);
}