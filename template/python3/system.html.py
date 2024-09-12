# system.html.py
# to run: python system.html.py

import os
import subprocess
import time
import asyncio
import aiofiles
from jinja2 import Environment, FileSystemLoader

async def run_script(script_name):
	try:
		if script_name.endswith('.js'):
			proc = await asyncio.create_subprocess_exec('node', script_name, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
		elif script_name.endswith('.php'):
			proc = await asyncio.create_subprocess_exec('php', script_name, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
		elif script_name.endswith('.py'):
			proc = await asyncio.create_subprocess_exec('python', script_name, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
		elif script_name.endswith('.sh'):
			proc = await asyncio.create_subprocess_exec('bash', script_name, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
		else:
			return f"Unsupported file type: {script_name}", "failure"

		stdout, stderr = await proc.communicate()
		if proc.returncode == 0:
			return stdout.decode().strip(), "success"
		else:
			return f"Error running {script_name}: {stderr.decode()}", "failure"
	except Exception as e:
		return f"Error running {script_name}: {str(e)}", "failure"

async def read_scripts_file(filename):
	scripts = {}
	async with aiofiles.open(filename, 'r') as f:
		lines = await f.readlines()
		for line in lines:
			script = line.strip()
			if script:
				function = script.split('_')[1]  # Assuming function name is the second part of the filename
				if function not in scripts:
					scripts[function] = []
				scripts[function].append(script)
	return scripts

async def generate_html():
	scripts = await read_scripts_file('scripts.txt')

	env = Environment(loader=FileSystemLoader('./template/html'))
	template = env.get_template('report_template.html')

	summary_data = []
	detailed_data = []

	for function, script_list in scripts.items():
		function_summary = {"function": function}
		function_details = {"function": function, "scripts": []}

		for ext in ['.js', '.php', '.py', '.sh']:
			script = next((s for s in script_list if s.endswith(ext)), None)
			if script:
				print(f"Running {script}...")
				output, status = await run_script(script)

				if not output:
					summary = "No output"
					status = "n/a"
				elif "error" in output.lower():
					status = "failed"
					summary = "failed"
				else:
					status = "success"
					summary = "success"

				function_summary[ext[1:]] = {"summary": summary, "status": status}
				function_details["scripts"].append({
					"name": script,
					"summary": summary,
					"status": status,
					"details": output
				})
			else:
				function_summary[ext[1:]] = {"summary": "N/A", "status": "n/a"}

		summary_data.append(function_summary)
		detailed_data.append(function_details)

	html_content = template.render(summary_data=summary_data, detailed_data=detailed_data)

	async with aiofiles.open('system.html', 'w') as f:
		await f.write(html_content)

async def main():
	start_time = time.time()
	print("Initiating system.html generation...")
	await generate_html()
	end_time = time.time()
	print(f"system.html has been generated successfully. Time elapsed: {end_time - start_time:.2f} seconds.")

if __name__ == "__main__":
	asyncio.run(main())

# end of system.html.py