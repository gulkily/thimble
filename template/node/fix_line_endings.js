#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

function standardizeLineEndings(filePath) {
	const content = fs.readFileSync(filePath, 'utf8');
	const standardizedContent = content.replace(/\r\n|\r/g, '\n');
	fs.writeFileSync(filePath, standardizedContent, 'utf8');
}

function processDirectory(directory) {
	const files = fs.readdirSync(directory, { withFileTypes: true });
	
	for (const file of files) {
		const fullPath = path.join(directory, file.name);
		
		if (file.isDirectory()) {
			processDirectory(fullPath);
		} else if (file.isFile() && /\.(py|js|sh|txt|html|php|pl|rb|css)$/.test(file.name)) {
			console.log(`Standardizing line endings in: ${fullPath}`);
			standardizeLineEndings(fullPath);
		}
	}
}

if (process.argv.length !== 3) {
	console.log("Usage: node fix_line_endings.js <directory>");
	process.exit(1);
}

const directory = process.argv[2];
if (!fs.existsSync(directory) || !fs.statSync(directory).isDirectory()) {
	console.log(`Error: ${directory} is not a valid directory`);
	process.exit(1);
}

processDirectory(directory);
console.log("Line ending standardization complete.");