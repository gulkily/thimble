// log.html.js
// to run: node log.html.js

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

function readFile(filePath) {
	return fs.readFileSync(filePath, 'utf-8');
}

function extractMetadata(content) {
	const authorMatch = content.match(/Author:\s*(.+)/i);
	const author = authorMatch ? authorMatch[1] : "";
	const hashtags = content.match(/#\w+/g) || [];
	return [author, hashtags];
}

function generateHtml(repoPath, outputFile) {
	const htmlTemplate = readFile('./template/html/page.html');
	const tableRowTemplate = readFile('./template/html/page_row.html');
	const cssStyle = readFile('./template/css/webmail.css');

	let tableRows = [];
	let fileCount = 0;

	function walkDir(dir) {
		const files = fs.readdirSync(dir);
		for (const file of files) {
			const filePath = path.join(dir, file);
			const stat = fs.statSync(filePath);
			if (stat.isDirectory()) {
				walkDir(filePath);
			} else if (file.endsWith('.txt')) {
				const relativePath = path.relative(repoPath, filePath);

				let commitTimestamp;
				try {
					const gitLog = execSync(`git log -1 --format=%cd --date=format:'%Y-%m-%d %H:%M:%S' -- "${relativePath}"`, { cwd: repoPath }).toString().trim();
					commitTimestamp = gitLog || 'N/A';
				} catch (error) {
					commitTimestamp = 'N/A';
				}

				const storedDate = path.basename(path.dirname(filePath));

				let author, hashtags;
				try {
					const content = fs.readFileSync(filePath, 'utf-8');
					[author, hashtags] = extractMetadata(content);
				} catch (error) {
					console.error(`Error reading file ${filePath}: ${error.message}`);
					author = 'Error';
					hashtags = [];
				}

				tableRows.push(tableRowTemplate
					.replace('{relative_path}', relativePath)
					.replace('{commit_timestamp}', commitTimestamp)
					.replace('{stored_date}', storedDate)
					.replace('{author}', author)
					.replace('{hashtags}', hashtags.join(', '))
				);

				fileCount++;
				if (fileCount >= 100) return;
			}
		}
	}

	walkDir(path.join(repoPath, 'message'));

	const title = 'THIMBLE';
	const htmlContent = htmlTemplate
		.replace(/{style}/g, cssStyle)
		.replace(/{table_rows}/g, tableRows.join(''))
		.replace(/{file_count}/g, fileCount)
		.replace(/{current_time}/g, new Date().toISOString().replace('T', ' ').substr(0, 19))
		.replace(/{title}/g, title);

	fs.writeFileSync(outputFile, htmlContent, 'utf-8');
}

if (require.main === module) {
	const repoPath = '.';  // Current directory
	const outputFile = 'log.html';
	generateHtml(repoPath, outputFile);
	console.log(`Report generated: ${outputFile}`);
}