// test_log.html.js
// to run: node test_log.html.js

const { exec } = require('child_process');
const fs = require('fs');
function runGenerateReport(script) {
	return new Promise((resolve, reject) => {
		const startTime = Date.now();
		exec(script, (error, stdout, stderr) => {
			const endTime = Date.now();
			if (error) {
				reject(error);
			} else {
				resolve({
					stdout,
					stderr,
					executionTime: (endTime - startTime) / 1000
				});
			}
		});
	});
}

function checkOutputFile(filePath) {
	return fs.existsSync(filePath) && fs.statSync(filePath).size > 0;
}

const scripts = [
	'python3 log.html.py',
	'php log.html.php',
	'node log.html.js',
	'bash log.html.sh'
];

async function runTests() {
	for (const script of scripts) {
		console.log(`\nTesting: ${script}`);

		try {
			// Run the script
			const { stdout, stderr, executionTime } = await runGenerateReport(script);

			// Check execution time
			if (executionTime >= 60) {
				throw new Error(`Script took too long to execute: ${executionTime.toFixed(2)} seconds`);
			}
			console.log(`Execution time: ${executionTime.toFixed(2)} seconds`);

			// Check if output file exists and is not empty
			if (!checkOutputFile('log.html')) {
				throw new Error("Output file 'log.html' is missing or empty");
			}
			console.log("Output file 'log.html' generated successfully");

			// Clean up
			fs.unlinkSync('log.html');
		} catch (error) {
			console.error(`Test failed: ${error.message}`);
			process.exit(1);
		}
	}

	console.log("\nAll tests passed successfully!");
}

runTests();

// end of test_log.html.js