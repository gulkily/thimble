#!/usr/bin/env python3

import os
import time
import subprocess
import unittest
import signal
import socket

class TestServerImplementations(unittest.TestCase):
    def port_status(self, port=8000):
        """Check if a port is listening"""
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            return s.connect_ex(('localhost', port)) == 0

    def find_process_on_port(self, port=8000):
        """Find process ID using the specified port"""
        try:
            return subprocess.check_output(['lsof', '-t', '-i', f':{port}']).decode().strip()
        except subprocess.CalledProcessError:
            return None

    def kill_port_process(self, port=8000):
        """Find and kill any process using the specified port"""
        pid = self.find_process_on_port(port)
        if pid:
            try:
                os.kill(int(pid), signal.SIGTERM)
                time.sleep(1)  # Wait for process to terminate
            except (ValueError, ProcessLookupError):
                pass

    def find_listening_port(self, process, start_port=8000, max_port=8010):
        """Find which port the server is actually listening on"""
        time.sleep(2)  # Give the server time to start
        for port in range(start_port, max_port):
            if self.port_status(port):
                return port
        return None

    def start_server(self, script, template_dir):
        """Start the server and find which port it's using"""
        cwd = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), template_dir)
        with open(os.devnull, 'w') as devnull:
            process = subprocess.Popen(script.split(), cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        
        # Find which port the server is using
        port = self.find_listening_port(process)
        if port is None:
            self.stop_server(process)
            raise RuntimeError(f"Server failed to start on any port: {script}")
        
        return process, port

    def stop_server(self, process):
        """Stop the server"""
        if process:
            process.terminate()
            process.wait()
            time.sleep(1)  # Wait for port to be freed

    def setUp(self):
        """Clean up any existing processes on common ports"""
        for port in range(8000, 8010):
            self.kill_port_process(port)

    def tearDown(self):
        """Clean up after tests"""
        for port in range(8000, 8010):
            self.kill_port_process(port)

    def test_server_implementations(self):
        server_scripts = [
            ('python3 start_server.py', 'template/python3'),
            ('ruby start_server.rb', 'template/ruby'),
            ('php start_server.php', 'template/php'),
            ('node start_server.js', 'template/node'),
            ('perl start_server.pl', 'template/perl'),
        ]

        print("\nTesting server implementations:")
        for script, template_dir in server_scripts:
            with self.subTest(implementation=template_dir):
                print(f"  {template_dir:20} ", end='', flush=True)
                
                # Start the server
                server_process = None
                try:
                    server_process, port = self.start_server(script, template_dir)
                    print(f"✓ (port {port})")
                finally:
                    # Always stop the server
                    if server_process:
                        self.stop_server(server_process)

if __name__ == '__main__':
    unittest.main(verbosity=1)