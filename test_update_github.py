# test_update_github.py
# to run: python3 test_update_github.py

import os
import subprocess
import random
import string
from datetime import datetime
import update_github

def random_string(length=8):
    return ''.join(random.choices(string.ascii_lowercase + string.digits, k=length))

def create_test_file(content):
    date_str = datetime.now().strftime("%Y-%m-%d")
    filename = f"{random_string()}.txt"
    dir_path = os.path.join("message", date_str)
    os.makedirs(dir_path, exist_ok=True)
    file_path = os.path.join(dir_path, filename)

    with open(file_path, 'w') as f:
        f.write(content)

    return file_path

def run_git_command(command):
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    output, error = process.communicate()
    return output.decode('utf-8').strip(), error.decode('utf-8').strip()

def check_git_log():
    result = subprocess.run(["git", "log", "-1", "--pretty=format:%s"], capture_output=True, text=True)
    return "Auto-commit" in result.stdout

def run_tests():
    print("Testing update_github.py")

    # Test 1: No changes to update
    update_github.update_github()
    print("Test 1 passed: No changes to update")

    # Test 2: Local changes
    file1 = create_test_file("Test content for local changes")
    run_git_command("git add .")
    run_git_command('git commit -m "Test commit"')
    update_github.update_github()
    assert check_git_log(), "Git commit not found"
    print("Test 2 passed: Local changes pushed")

    # Test 3: Remote changes
    run_git_command("git reset --hard HEAD~1")
    file2 = create_test_file("Test content for remote changes")
    run_git_command("git add .")
    run_git_command('git commit -m "Remote test commit"')
    run_git_command("git push")
    run_git_command("git reset --hard HEAD~1")
    update_github.update_github()
    assert "Remote test commit" in run_git_command("git log -1 --pretty=format:%s")[0], "Remote changes not merged"
    print("Test 3 passed: Remote changes merged")

    # Test 4: Diverged history
    file3 = create_test_file("Test content for diverged history")
    run_git_command("git add .")
    run_git_command('git commit -m "Local diverged commit"')
    run_git_command("git push origin HEAD:test-branch")
    run_git_command("git reset --hard HEAD~1")
    file4 = create_test_file("Test content for remote diverged history")
    run_git_command("git add .")
    run_git_command('git commit -m "Remote diverged commit"')
    run_git_command("git push")
    run_git_command("git reset --hard HEAD~1")
    update_github.update_github()
    assert "Remote diverged commit" in run_git_command("git log -1 --pretty=format:%s")[0], "Diverged history not resolved"
    print("Test 4 passed: Diverged history resolved")

    print("All tests passed for update_github.py")

if __name__ == "__main__":
    run_tests()
