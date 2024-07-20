// generate_report.js
// to run: node generate_report.js

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
        // ... (rest of the walkDir function remains the same)
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
    const outputFile = 'index.html';
    generateHtml(repoPath, outputFile);
    console.log(`Report generated: ${outputFile}`);
}
