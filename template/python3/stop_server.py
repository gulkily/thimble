# stop_server.py
# to run: python3 stop_server.py

import os
import signal
import subprocess
import sys

def find_pid():
	try:
	# Use 'ps' command to find the process running start_server.py
	output = subprocess.check_output(["ps", "aux"]).decode()
	for line in output.split('\n'):
	    if "python" in line and "start_server.py" in line:
		return int(line.split()[1])
	except subprocess.CalledProcessError:
	return None

def stop_server():
	pid = find_pid()
	if pid:
	try:
	    os.kill(pid, signal.SIGTERM)
	    print(f"Server process (PID: {pid}) has been terminated.")
	except ProcessLookupError:
	    print("Server process not found.")
	except PermissionError:
	    print("Permission denied. You may need to run this script with sudo.")
	else:
	print("No running server process found.")

if __name__ == "__main__":
	stop_server()