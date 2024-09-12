# test_log.html.py
# to run: python3 test_log.html.py

import os
import subprocess
import time

def run_generate_report(script):
	process = subprocess.Popen(script.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	stdout, stderr = process.communicate()
	return process.returncode, stdout.decode(), stderr.decode()

def check_output_file(file_path):
	return os.path.exists(file_path) and os.path.getsize(file_path) > 0

scripts = [
	'python3 log.html.py',
	'php log.html.php',
	'node log.html.js',
	'bash log.html.sh'
]

for script in scripts:
	print(f"\nTesting: {script}")
	
	# Run the script
	start_time = time.time()
	return_code, stdout, stderr = run_generate_report(script)
	end_time = time.time()
	
	# Check return code
	assert return_code == 0, f"Script failed with return code {return_code}"
	print("Script executed successfully")
	
	# Check execution time
	execution_time = end_time - start_time
	assert execution_time < 60, f"Script took too long to execute: {execution_time:.2f} seconds"
	print(f"Execution time: {execution_time:.2f} seconds")
	
	# Check if output file exists and is not empty
	assert check_output_file('log.html'), "Output file 'log.html' is missing or empty"
	print("Output file 'log.html' generated successfully")
	
	# Clean up
	os.remove('log.html')

print("\nAll tests passed successfully!")

# end of test_log.html.py