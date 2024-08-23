# test_start_server.py v2
# to run: python3 test_start_server.py

import os
import time
import subprocess

def port_status(port=8000):
    # checks whether port 8000 is listening
    return os.system(f'netstat -tulnp 2>/dev/null | grep {port}') == 0

def start_server(script):
    # start the server, forked
    process = subprocess.Popen(script.split())
    time.sleep(2)
    return process

def stop_server(process):
    # stop the server
    process.terminate()
    process.wait()

# SETUP:

# check for listening on port 8000 (should be false):
assert not port_status(), "Port 8000 is already in use"

print("PASS: SETUP")

# TESTS:

server_scripts = [
    'python3 start_server.py',
    'ruby start_server.rb',
    'php start_server.php',
    'node start_server.js',
    'perl start_server.pl',
]

for script in server_scripts:
    print(f"\nTesting: {script}")

    # Start the server
    server_process = start_server(script)

    # Verify that the server is listening on port 8000
    assert port_status(), f"Server failed to start: {script}"
    print("Server started successfully")

    # Stop the server
    stop_server(server_process)

    # Verify that the server is no longer listening
    assert not port_status(), f"Server failed to stop: {script}"
    print("Server stopped successfully")

print("\nAll tests passed successfully!")

# end of test_start_server.py