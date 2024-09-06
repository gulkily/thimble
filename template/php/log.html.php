<?php
// log.html.php
// to run: php log.html.php

function read_file($file_path) {
    return file_get_contents($file_path);
}

function extract_metadata($content) {
    $author = "";
    if (preg_match('/Author:\s*(.+)/i', $content, $matches)) {
        $author = $matches[1];
    }
    preg_match_all('/#\w+/', $content, $hashtags);
    return [$author, $hashtags[0]];
}

function get_last_commit_date($file_path) {
    $command = sprintf('git log -1 --format="%%ci" -- "%s"', $file_path);
    $output = trim(shell_exec($command));
    return $output ? date('Y-m-d H:i:s', strtotime($output)) : 'N/A';
}

function generate_html($repo_path, $output_file) {
    $HTML_TEMPLATE = read_file('./template/html/page.html');
    $TABLE_ROW_TEMPLATE = read_file('./template/html/page_row.html');
    $CSS_STYLE = read_file('./template/css/green.css');

    $table_rows = [];
    $file_count = 0;
    $iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($repo_path . "/message"));

    foreach ($iterator as $file) {
        if ($file->isFile() && $file->getExtension() == 'txt') {
            $file_path = $file->getPathname();
            $relative_path = substr($file_path, strlen($repo_path) + 1);

            $commit_timestamp = get_last_commit_date($file_path);
            $stored_date = basename(dirname($file_path));

            try {
                $content = file_get_contents($file_path);
                list($author, $hashtags) = extract_metadata($content);
            } catch (Exception $e) {
                echo "Error reading file $file_path: " . $e->getMessage() . "\n";
                $author = "Error";
                $hashtags = [];
            }

			$table_rows[] = str_replace(
				[
					'{relative_path}',
					'{commit_timestamp}',
					'{stored_date}',
					'{author}',
					'{hashtags}'
				],
				[
					$relative_path,
					$commit_timestamp,
					$stored_date,
					$author,
					implode(', ', $hashtags)
				],
				$TABLE_ROW_TEMPLATE
			);


            $file_count++;
            if ($file_count >= 100) {
                break;
            }
        }
    }

	$html_content = strtr($HTML_TEMPLATE, [
		'{style}' => $CSS_STYLE,
		'{table_rows}' => implode('', $table_rows),
		'{file_count}' => $file_count,
		'{current_time}' => date('Y-m-d H:i:s'),
		'{title}' => "THIMBLE"
	]);

    file_put_contents($output_file, $html_content);
}

$repo_path = ".";  // Current directory
$output_file = 'log.html';
generate_html($repo_path, $output_file);
echo "Report generated: $output_file\n";