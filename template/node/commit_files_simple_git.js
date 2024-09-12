// commit_files.js
// to run: node commit_files.js

const fs = require('fs').promises;
const path = require('path');
const crypto = require('crypto');
const simpleGit = require('simple-git');
const git = simpleGit();

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

async function commitTextFiles(repoPath = '.') {
	try {
		const status = await git.status();

		if (!status.modified.length && !status.not_added.length) {
			console.log("No changes to commit.");
			return;
		}

		const allChangedFiles = [...status.modified, ...status.not_added];
		const txtFiles = allChangedFiles.filter(file => file.endsWith('.txt'));

		if (!txtFiles.length) {
			console.log("No uncommitted .txt files found.");
			return;
		}

		const metadataFiles = [];

		for (const filePath of txtFiles) {
			const fullPath = path.join(repoPath, filePath);
			try {
				const content = await fs.readFile(fullPath, 'utf-8');
				const metadata = await extractMetadata(content, fullPath);
				const metadataFile = await storeMetadata(fullPath, metadata);
				metadataFiles.push(metadataFile);

				console.log(`File: ${filePath}`);
				console.log(`Author: ${metadata.author}`);
				console.log(`Title: ${metadata.title}`);
				console.log(`Hashtags: ${metadata.hashtags.join(', ')}`);
				console.log(`File Hash: ${metadata.file_hash}`);
				console.log();
			} catch (e) {
				console.error(`Error processing file ${filePath}: ${e.message}`);
			}
		}

		await git.add([...txtFiles, ...metadataFiles]);

		const commitMessage = `Auto-commit ${txtFiles.length} text files and metadata on ${new Date().toISOString()} by commit_files.js`;
		await git.commit(commitMessage);

		console.log(`Committed ${txtFiles.length} text files and their metadata.`);
		console.log("Commit message:", commitMessage);
	} catch (e) {
		console.error(`Error: ${e.message}`);
	}
}

if (require.main === module) {
	commitTextFiles();
}