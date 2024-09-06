# test_chat.html.py - Test the chat.html.* scripts
# to run: python3 test_chat.html.py

import subprocess
import time
import concurrent.futures
import os

def run_script(command, script_name):
    start_time = time.time()
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=60)
        end_time = time.time()
        return {
            'script': script_name,
            'success': result.returncode == 0,
            'output': result.stdout,
            'error': result.stderr,
            'time': end_time - start_time
        }
    except subprocess.TimeoutExpired:
        return {
            'script': script_name,
            'success': False,
            'output': '',
            'error': 'Timeout after 60 seconds',
            'time': 60
        }
    except Exception as e:
        return {
            'script': script_name,
            'success': False,
            'output': '',
            'error': str(e),
            'time': time.time() - start_time
        }

def run_tests(scripts):
    with concurrent.futures.ThreadPoolExecutor() as executor:
        futures = []
        for script, command in scripts.items():
            futures.append(executor.submit(run_script, command, script))
        
        results = []
        for future in concurrent.futures.as_completed(futures):
            results.append(future.result())
    
    return results

def print_results(results):
    for result in results:
        print(f"Script: {result['script']}")
        print(f"Success: {'Yes' if result['success'] else 'No'}")
        print(f"Execution Time: {result['time']:.2f} seconds")
        if result['output']:
            print("Output:")
            print(result['output'])
        if result['error']:
            print("Error:")
            print(result['error'])
        print("-" * 50)

if __name__ == "__main__":
    scripts = {
        'chat.html.php': ['php', 'chat.html.php', '--debug'],
        'chat.html.pl': ['perl', 'chat.html.pl', '--debug'],
        'chat.html.py': ['python3', 'chat.html.py', '--debug']
    }

    results = run_tests(scripts)
    print_results(results)


# end of test_chat.html.py