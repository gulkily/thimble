import os
import subprocess
import time

def run_script(script_name):
    try:
        print(f"[THIMBLE] Executing {script_name}...")
        if script_name.endswith('.js'):
            output = subprocess.check_output(['node', script_name], stderr=subprocess.STDOUT, universal_newlines=True)
        elif script_name.endswith('.php'):
            output = subprocess.check_output(['php', script_name], stderr=subprocess.STDOUT, universal_newlines=True)
        elif script_name.endswith('.py'):
            output = subprocess.check_output(['python', script_name], stderr=subprocess.STDOUT, universal_newlines=True)
        elif script_name.endswith('.sh'):
            output = subprocess.check_output(['bash', script_name], stderr=subprocess.STDOUT, universal_newlines=True)
        else:
            return f"[ERROR] Unsupported file type: {script_name}"
        print(f"[THIMBLE] {script_name} execution completed.")
        return output.strip()
    except subprocess.CalledProcessError as e:
        return f"[ERROR] Execution failed for {script_name}: {e.output}"

def generate_html():
    scripts = [
        'test_commit_files.js',
        'test_commit_files.php',
        'test_commit_files.py',
        'test_generate_report.js',
        'test_generate_report.php',
        'test_generate_report.py',
        'test_generate_report.sh',
        'test_start_server.php',
        'test_start_server.py'
    ]

    html_content = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>THIMBLE System Status</title>
        <style>
            body { font-family: 'Courier New', monospace; line-height: 1.6; padding: 20px; background-color: #000; color: #0F0; }
            h1 { color: #0F0; text-align: center; text-transform: uppercase; }
            h2 { color: #0F0; border-bottom: 1px solid #0F0; }
            pre { background-color: #001100; padding: 10px; border-radius: 5px; border: 1px solid #0F0; }
            .summary { font-weight: bold; margin-bottom: 10px; }
            .details { margin-bottom: 20px; }
            .status { color: #FF0; }
        </style>
    </head>
    <body>
        <h1>THIMBLE System Status</h1>
    """

    print("[THIMBLE] Initiating system status report generation...")
    total_scripts = len(scripts)
    for index, script in enumerate(scripts, 1):
        print(f"[THIMBLE] Processing script {index} of {total_scripts}: {script}")
        output = run_script(script)
        summary = output.split('\n')[0] if output else "No output"

        html_content += f"""
        <h2>{script}</h2>
        <div class="summary">Summary: {summary}</div>
        <div class="details">
            <h3>Details:</h3>
            <pre>{output}</pre>
        </div>
        """



    html_content += """
    </body>
    </html>
    """

    with open('system.html', 'w') as f:
        f.write(html_content)

if __name__ == "__main__":
    print("[THIMBLE] Initiating system status report...")
    start_time = time.time()
    generate_html()
    end_time = time.time()
    print(f"[THIMBLE] system.html has been generated. Time elapsed: {end_time - start_time:.2f} seconds.")
    print("[THIMBLE] Mission accomplished. Terminating process.")