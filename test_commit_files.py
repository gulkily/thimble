import os
import subprocess
import tempfile
import shutil
import unittest
import json

class TestCommitFiles(unittest.TestCase):
    def setUp(self):
        # Create a temporary directory
        self.test_dir = tempfile.mkdtemp()
        
        # Initialize a git repository
        subprocess.run(['git', 'init', self.test_dir], check=True)
        
        # Change to the test directory
        os.chdir(self.test_dir)
        
        # Set up git config
        subprocess.run(['git', 'config', 'user.email', 'test@example.com'], check=True)
        subprocess.run(['git', 'config', 'user.name', 'Test User'], check=True)

    def tearDown(self):
        # Change back to the original directory
        os.chdir(os.path.dirname(os.path.realpath(__file__)))
        
        # Remove the temporary directory
        shutil.rmtree(self.test_dir)

    def create_test_file(self, filename, content):
        with open(os.path.join(self.test_dir, filename), 'w') as f:
            f.write(content)

    def run_commit_script(self, script_name):
        if script_name.endswith('.py'):
            result = subprocess.run(['python3', script_name], capture_output=True, text=True)
        elif script_name.endswith('.php'):
            result = subprocess.run(['php', script_name], capture_output=True, text=True)
        else:
            raise ValueError(f"Unsupported script type: {script_name}")
        return result.stdout

    def test_commit_files(self):
        # Create test files
        self.create_test_file('test1.txt', 'Author: John Doe\nThis is test file 1\n#tag1 #tag2')
        self.create_test_file('test2.txt', 'Author: Jane Smith\nThis is test file 2\n#tag3')
        self.create_test_file('not_a_text_file.dat', 'This should be ignored')

        # Copy the commit scripts to the test directory
        shutil.copy('commit_files.py', self.test_dir)
        shutil.copy('commit_files.php', self.test_dir)

        # Run both scripts
        py_output = self.run_commit_script('commit_files.py')
        php_output = self.run_commit_script('commit_files.php')

        # Check if both scripts produced similar output
        self.assertIn("Committed 2 text files", py_output)
        self.assertIn("Committed 2 text files", php_output)

        # Check if metadata files were created
        metadata_dir = os.path.join(self.test_dir, 'metadata')
        self.assertTrue(os.path.exists(metadata_dir))
        self.assertEqual(len(os.listdir(metadata_dir)), 2)

        # Check metadata content
        for filename in ['test1.txt.json', 'test2.txt.json']:
            with open(os.path.join(metadata_dir, filename), 'r') as f:
                metadata = json.load(f)
                self.assertIn('author', metadata)
                self.assertIn('title', metadata)
                self.assertIn('hashtags', metadata)
                self.assertIn('file_hash', metadata)

        # Check git log
        result = subprocess.run(['git', 'log', '--oneline'], capture_output=True, text=True)
        self.assertIn("Auto-commit 2 text files", result.stdout)

if __name__ == '__main__':
    unittest.main()
