// generate_chat_html.js
// to run: node generate_chat_html.js

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const chardet = require('chardet');
const argparse = require('argparse');

// Debug flag
let DEBUG = false;

function debugPrint(...args) {
    if (DEBUG) {
        console.log(...args);
    }
}

debugPrint("Script started.");

function readFile(filePath) {
    debugPrint(`Reading file: ${filePath}`);
    const content = fs.readFileSync(filePath, 'utf8');
    debugPrint(`File read successfully. Content length: ${content.length} characters`);
    return content;
}

function extractMetadata(content) {
    debugPrint("Extracting metadata from content");
    const authorMatch = content.match(/Author:\s*(.+)/i);
    const author = authorMatch ? authorMatch[1] : "Unknown";
    const hashtags = (content.match(/#\w+/g) || []);
    debugPrint(`Extracted metadata - Author: ${author}, Hashtags: ${hashtags}`);
    return [author, hashtags];
}

function truncateMessage(content, maxLength = 300) {
    debugPrint(`Truncating message. Original length: ${content.length}`);
    if (content.length <= maxLength) {
        debugPrint("Message does not need truncation");
        return [content, false];
    }
    const truncated = content.slice(0, maxLength) + "...";
    debugPrint(`Message truncated. New length: ${truncated.length}`);
    return [truncated, true];
}

function generateChatHtml(repoPath, outputFile, maxMessages = 50, maxMessageLength = 300, title = "THIMBLE Chat") {
    debugPrint(`Generating chat HTML. Repo path: ${repoPath}, Output file: ${outputFile}`);
    const HTML_TEMPLATE = readFile('./template/html/chat_page.html');
    const MESSAGE_TEMPLATE = readFile('./template/html/chat_message.html');
    const CSS_STYLE = readFile('./template/css/chat_style.css');
    const JS_TEMPLATE = readFile('./template/js/chat.js');

    const messages = [];
    const messageDir = path.join(repoPath, "message");
    debugPrint(`Scanning directory: ${messageDir}`);

    function scanDirectory(directory) {
        debugPrint(`Scanning directory: ${directory}`);
        const entries = fs.readdirSync(directory, { withFileTypes: true });
        for (const entry of entries) {
            if (entry.isFile() && entry.name.endsWith(".txt")) {
                debugPrint(`Processing file: ${path.join(directory, entry.name)}`);
                processFile(path.join(directory, entry.name));
            } else if (entry.isDirectory()) {
                scanDirectory(path.join(directory, entry.name));
            }
        }
    }

    function processFile(filePath) {
        debugPrint(`Processing file: ${filePath}`);
        const relativePath = path.relative(repoPath, filePath);

        let commitTimestamp;
        try {
            const gitLog = execSync(`git log -1 --format=%ct -- "${relativePath}"`, { cwd: repoPath }).toString().trim();
            commitTimestamp = new Date(parseInt(gitLog) * 1000);
            debugPrint(`Commit timestamp: ${commitTimestamp}`);
        } catch (error) {
            debugPrint("No commit found for file, using minimum date");
            commitTimestamp = new Date(0);
        }

        try {
            const rawData = fs.readFileSync(filePath);
            const detectedEncoding = chardet.detect(rawData);
            debugPrint(`Detected encoding: ${detectedEncoding}`);
            const content = fs.readFileSync(filePath, detectedEncoding);
            const [author, hashtags] = extractMetadata(content);

            const cleanedContent = content.replace(/author:\s*.+/i, '').trim();
            debugPrint(`Processed content. Length: ${cleanedContent.length}`);

            messages.push({
                author,
                content: cleanedContent,
                timestamp: commitTimestamp,
                hashtags
            });
            debugPrint(`Message added. Total messages: ${messages.length}`);
        } catch (error) {
            debugPrint(`Error reading file ${filePath}: ${error.message}`);
            messages.push({
                author: "Error",
                content: "Error reading message",
                timestamp: commitTimestamp,
                hashtags: []
            });
        }
    }

    scanDirectory(messageDir);

    debugPrint("Sorting messages by timestamp");
    messages.sort((a, b) => b.timestamp - a.timestamp);

    // Limit the number of messages
    messages.splice(maxMessages);

    const chatMessages = messages.map((msg, idx) => {
        debugPrint(`Processing message ${idx + 1}/${messages.length}`);
        const [truncatedContent, isTruncated] = truncateMessage(msg.content, maxMessageLength);
        const expandLink = `<a href="#" class="expand-link" data-message-id="${idx}">${isTruncated ? "Show More" : ""}</a>`;
        const fullContent = isTruncated ? `<div class="full-message" id="full-message-${idx}" style="display: none;">${msg.content}</div>` : '';

        return MESSAGE_TEMPLATE
            .replace('{author}', msg.author)
            .replace('{content}', truncatedContent)
            .replace('{full_content}', fullContent)
            .replace('{expand_link}', expandLink)
            .replace('{timestamp}', msg.timestamp.toISOString().replace('T', ' ').substr(0, 19))
            .replace('{hashtags}', msg.hashtags.join(' '));
    });

    debugPrint("Generating final HTML content");
    let htmlContent = HTML_TEMPLATE
        .replace('{style}', CSS_STYLE)
        .replace('{chat_messages}', chatMessages.join(''))
        .replace('{message_count}', messages.length)
        .replace('{current_time}', new Date().toISOString().replace('T', ' ').substr(0, 19))
        .replace('{title}', title);

    htmlContent = htmlContent.replace('</body>', `<script>${JS_TEMPLATE}</script></body>`);

    debugPrint(`Writing HTML content to file: ${outputFile}`);
    fs.writeFileSync(outputFile, htmlContent, 'utf8');
}

if (require.main === module) {
    const parser = new argparse.ArgumentParser({
        description: "Generate chat HTML from repository messages."
    });
    parser.add_argument("--repo_path", { default: ".", help: "Path to the repository" });
    parser.add_argument("--output_file", { default: "chat.html", help: "Output HTML file name" });
    parser.add_argument("--max_messages", { type: 'int', default: 50, help: "Maximum number of messages to display" });
    parser.add_argument("--max_message_length", { type: 'int', default: 300, help: "Maximum length of each message before truncation" });
    parser.add_argument("--title", { default: "THIMBLE Chat", help: "Title of the chat page" });
    parser.add_argument("--debug", { action: "store_true", help: "Enable debug output" });

    const args = parser.parse_args();

    // Set the debug flag based on the command-line argument
    DEBUG = args.debug;

    generateChatHtml(args.repo_path, args.output_file, args.max_messages, args.max_message_length, args.title);
    debugPrint(`Chat log generated: ${args.output_file}`);
    debugPrint("Script completed.");
}
