// test_commit_files.js
// to run: node test_commit_files.js

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

function randomString(length = 8) {
    return crypto.randomBytes(length).toString('hex');
}

function createTestFile(content) {
    const dateStr = new Date().toISOString().split('T')[0];
    const filename = `${randomString()}.txt`;
    const dirPath = path.join('message', dateStr);
    fs.mkdirSync(dirPath, { recursive: true });
    const filePath = path.join(dirPath, filename);
    
    fs.writeFileSync(filePath, content);
    
    return filePath;
}

function runCommitFiles(script) {
    execSync(script, { stdio: 'inherit' });
}

function checkGitLog() {
    const logOutput = execSync('git log -1 --pretty=format:%s', { encoding: 'utf-8' });
    return logOutput.includes('Auto-commit');
}

function checkMetadataFile(filename) {
    const metadataFile = path.join(path.dirname(filename), 'metadata', path.basename(filename) + '.json');
    if (!fs.existsSync(metadataFile)) {
        return false;
    }
    const metadata = JSON.parse(fs.readFileSync(metadataFile, 'utf-8'));
    return ['author', 'title', 'hashtags', 'file_hash'].every(key => key in metadata);
}

function runTests(script) {
    console.log(`Testing ${script}`);

    // Test 1: Commit a single file
    const file1 = createTestFile("Author: John Doe\nThe Beauty of Nature\n\nNature's beauty is an awe-inspiring spectacle that never fails to amaze us. From the grandeur of mountains to the delicacy of a flower, it reminds us of the world's magnificence.\n\n#nature #beauty #inspiration");
    runCommitFiles(script);
    if (!checkGitLog()) throw new Error('Git commit not found');
    if (!checkMetadataFile(file1)) throw new Error('Metadata file not created or invalid');
    console.log('Test 1 passed: Single file commit');

    // Test 2: Commit multiple files
    const file2 = createTestFile("Author: Jane Smith\nThe Art of Cooking\n\nCooking is not just about sustenance; it's an art form that engages all our senses. The sizzle of a pan, the aroma of spices, and the vibrant colors of fresh ingredients all come together to create culinary masterpieces.\n\n#cooking #art #food");
    const file3 = createTestFile("Author: Bob Johnson\nThe Joy of Learning\n\nLearning is a lifelong journey that opens doors to new worlds. Whether it's picking up a new skill or diving deep into a subject, the process of discovery and growth is incredibly rewarding.\n\n#learning #education #growth");
    runCommitFiles(script);
    if (!checkGitLog()) throw new Error('Git commit not found');
    if (!checkMetadataFile(file2) || !checkMetadataFile(file3)) throw new Error('Metadata files not created or invalid');
    console.log('Test 2 passed: Multiple file commit');

    // Test 3: No changes to commit
    runCommitFiles(script);
    console.log('Test 3 passed: No changes to commit');

    console.log(`All tests passed for ${script}`);
}

const scripts = [
    'python3 commit_files.py',
    'node commit_files.js',
    'php commit_files.php',
    'perl commit_files.pl',
    'ruby commit_files.rb'
];

scripts.forEach(runTests);
