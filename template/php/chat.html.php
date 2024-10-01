<?php
// chat.html.php
// to run: php chat.html.php

function debug_print(...$args) {
	if (DEBUG) {
		echo implode(' ', $args) . "\n";
	}
}

function read_file($file_path) {
	return file_get_contents($file_path);
}

function extract_metadata($content) {
	$author = preg_match('/Author:\s*(.+)/i', $content, $matches) ? $matches[1] : "Unknown";
	preg_match_all('/#\w+/', $content, $hashtags);
	return [$author, $hashtags[0]];
}

function truncate_message($content, $max_length = 300) {
	if (mb_strlen($content) <= $max_length) {
		return [$content, false];
	}
	return [mb_substr($content, 0, $max_length) . "...", true];
}

function process_file($file_path, $repo_path) {
	$relative_path = str_replace($repo_path . '/', '', $file_path);
	try {
		$modification_time = new DateTime('@' . filemtime($file_path));
		$modification_time->setTimezone(new DateTimeZone('UTC'));
		$content = file_get_contents($file_path);
		[$author, $hashtags] = extract_metadata($content);
		$content = preg_replace('/author:\s*.+/i', '', $content);
		$content = trim($content);
		return [
			'author' => $author,
			'content' => $content,
			'timestamp' => $modification_time,
			'hashtags' => $hashtags,
			'file_path' => $file_path
		];
	} catch (Exception $e) {
		debug_print("Error reading file $file_path: " . $e->getMessage());
		return null;
	}
}

function generate_chat_html($repo_path, $output_file, $max_messages = 50, $max_message_length = 300, $title = "THIMBLE Chat") {
	$HTML_TEMPLATE = read_file('./template/html/chat_page.html');
	$MESSAGE_TEMPLATE = read_file('./template/html/chat_message.html');
	$CSS_STYLE = read_file('./template/css/chat_style.css');
	$JS_TEMPLATE = read_file('./template/js/chat.js');

	$message_dir = $repo_path . "/message";

	$file_paths = [];
	$iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($message_dir));
	foreach ($iterator as $file) {
		if ($file->isFile() && $file->getExtension() === 'txt') {
			$file_paths[] = $file->getPathname();
		}
	}

	$messages = array_map(function($file_path) use ($repo_path) {
		return process_file($file_path, $repo_path);
	}, $file_paths);

	$messages = array_filter($messages);
	usort($messages, function($a, $b) {
		$cmp = $b['timestamp']->getTimestamp() - $a['timestamp']->getTimestamp();
		return $cmp === 0 ? strcmp($a['file_path'], $b['file_path']) : $cmp;
	});
	$messages = array_slice($messages, 0, $max_messages);

	$chat_messages = [];
	foreach ($messages as $idx => $msg) {
		[$truncated_content, $is_truncated] = truncate_message($msg['content'], $max_message_length);
		$expand_link = $is_truncated ? "<a href=\"#\" class=\"expand-link\" data-message-id=\"$idx\">Show More</a>" : "";
		$full_content = $is_truncated ? "<div class=\"full-message\" id=\"full-message-$idx\" style=\"display: none;\">{$msg['content']}</div>" : '';

		$chat_messages[] = str_replace(
			['{author}', '{content}', '{full_content}', '{expand_link}', '{timestamp}', '{hashtags}'],
			[$msg['author'], $truncated_content, $full_content, $expand_link, $msg['timestamp']->format('Y-m-d H:i:s'), implode(' ', $msg['hashtags'])],
			$MESSAGE_TEMPLATE
		);
	}

	$html_content = str_replace(
		['{style}', '{chat_messages}', '{message_count}', '{current_time}', '{title}'],
		[$CSS_STYLE, implode('', $chat_messages), count($messages), (new DateTime())->format('Y-m-d H:i:s'), $title],
		$HTML_TEMPLATE
	);

	$html_content = str_replace('</body>', "<script>$JS_TEMPLATE</script></body>", $html_content);

	file_put_contents($output_file, $html_content);
}

// Command line argument parsing
$options = getopt("", ["repo_path:", "output_file:", "max_messages:", "max_message_length:", "title:", "debug"]);

$repo_path = $options['repo_path'] ?? '.';
$output_file = $options['output_file'] ?? 'chat.html';
$max_messages = isset($options['max_messages']) ? intval($options['max_messages']) : 50;
$max_message_length = isset($options['max_message_length']) ? intval($options['max_message_length']) : 300;
$title = $options['title'] ?? 'THIMBLE Chat';
define('DEBUG', isset($options['debug']));

date_default_timezone_set('UTC');

generate_chat_html($repo_path, $output_file, $max_messages, $max_message_length, $title);
debug_print("Chat log generated: $output_file");
debug_print("Script completed.");