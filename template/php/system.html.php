<?php
// system.html.php
// to run: php system.html.php

function run_script($script_name) {
	$output = '';
	$status = 'success';

	if (substr($script_name, -3) === '.js') {
		exec("node $script_name 2>&1", $output, $return_var);
	} elseif (substr($script_name, -4) === '.php') {
		exec("php $script_name 2>&1", $output, $return_var);
	} elseif (substr($script_name, -3) === '.py') {
		exec("python $script_name 2>&1", $output, $return_var);
	} elseif (substr($script_name, -3) === '.sh') {
		exec("bash $script_name 2>&1", $output, $return_var);
	} else {
		return array("Unsupported file type: $script_name", "failure");
	}

	$output = implode("\n", $output);
	if ($return_var !== 0) {
		$status = 'failure';
		$output = "Error running $script_name: $output";
	}

	return array($output, $status);
}

function read_scripts_file($filename) {
	$scripts = array();
	$lines = file($filename, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
	foreach ($lines as $line) {
		$script = trim($line);
		if ($script) {
			$function = explode('_', $script)[1];
			if (!isset($scripts[$function])) {
				$scripts[$function] = array();
			}
			$scripts[$function][] = $script;
		}
	}
	return $scripts;
}

function generate_html() {
	$scripts = read_scripts_file('scripts.txt');

	$summary_data = array();
	$detailed_data = array();

	foreach ($scripts as $function => $script_list) {
		$function_summary = array("function" => $function);
		$function_details = array("function" => $function, "scripts" => array());

		foreach (array('.js', '.php', '.py', '.sh') as $ext) {
			$script = null;
			foreach ($script_list as $s) {
				if (substr($s, -strlen($ext)) === $ext) {
					$script = $s;
					break;
				}
			}

			if ($script) {
				echo "Running $script...\n";
				list($output, $status) = run_script($script);

				if (!$output) {
					$summary = "No output";
					$status = "n/a";
				} elseif (stripos($output, "error") !== false) {
					$status = "failed";
					$summary = "failed";
				} else {
					$status = "success";
					$summary = "success";
				}

				$function_summary[substr($ext, 1)] = array("summary" => $summary, "status" => $status);
				$function_details["scripts"][] = array(
					"name" => $script,
					"summary" => $summary,
					"status" => $status,
					"details" => $output
				);
			} else {
				$function_summary[substr($ext, 1)] = array("summary" => "N/A", "status" => "n/a");
			}
		}

		$summary_data[] = $function_summary;
		$detailed_data[] = $function_details;
	}

	$template = file_get_contents('./template/html/system_template.html');
	$css_content = file_get_contents('./template/css/styles.css');

	$html_content = str_replace(
		array('{{ css_content }}', '{{ title }}', '{{ current_time }}'),
		array($css_content, 'Thimble System Report', date('Y-m-d H:i:s')),
		$template
	);

	// Replace summary_data and detailed_data placeholders
	$summary_html = '';
	foreach ($summary_data as $item) {
		$summary_html .= "<tr>
			<td>{$item['function']}</td>
			<td class=\"{$item['js']['status']}\">{$item['js']['summary']}</td>
			<td class=\"{$item['php']['status']}\">{$item['php']['summary']}</td>
			<td class=\"{$item['py']['status']}\">{$item['py']['summary']}</td>
			<td class=\"{$item['sh']['status']}\">{$item['sh']['summary']}</td>
		</tr>";
	}
	$html_content = str_replace('{{ summary_data }}', $summary_html, $html_content);

	$detailed_html = '';
	foreach ($detailed_data as $function) {
		$detailed_html .= "<div class=\"function-group\">
			<h3>{$function['function']}</h3>";
		foreach ($function['scripts'] as $script) {
			$detailed_html .= "<div class=\"script-details\">
				<h4>{$script['name']}</h4>
				<p class=\"summary {$script['status']}\">Summary: {$script['summary']}</p>
				<div class=\"details\">
					<h5>Details:</h5>
					<pre>{$script['details']}</pre>
				</div>
			</div>";
		}
		$detailed_html .= "</div>";
	}
	$html_content = str_replace('{{ detailed_data }}', $detailed_html, $html_content);

	file_put_contents('system.html', $html_content);
}

$start_time = microtime(true);
echo "Initiating system.html generation...\n";
generate_html();
$end_time = microtime(true);
$execution_time = $end_time - $start_time;
echo "system.html has been generated successfully. Time elapsed: " . number_format($execution_time, 2) . " seconds.\n";