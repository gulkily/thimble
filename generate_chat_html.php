<?php
// generate_chat_html.php
// to run: php generate_chat_html.php

// Debug flag
$DEBUG = false;

function debug_print($message) {
    global $DEBUG;
    if ($DEBUG) {
        echo $message . "\n";
    }
}

debug_print("Script started.");

function read_file($file_path) {
    debug_print("Reading file: $file_path");
    $content = file_get_contents($file_path);
    debug_print("File read successfully. Content length: " . strlen($content) . " characters");
    return $content;
}

function extract_metadata($content) {
    debug_print("Extracting metadata from content");
    $author = preg_match('/Author:\s*(.+)/i', $content, $matches) ? $matches[1] : "Unknown";
    preg_match_all('/#\w+/', $content, $hashtags);
    $hashtags = $hashtags[0];
    debug_print("Extracted metadata - Author: $author, Hashtags: " . implode(", ", $hashtags));
    return [$author, $hashtags];
}

function truncate_message($content, $max_length = 300) {
    debug_print("Truncating message. Original length: " . strlen($content));
    if (strlen($content) <= $max_length) {
        debug_print("Message does not need truncation");
        return [$content, false];
    }
    $truncated = substr($content, 0, $max_length) . "...";
    debug_print("Message truncated. New length: " . strlen($truncated));
    return [$truncated, true];
}

function scan_directory($directory, &$messages, $repo_path) {
    debug_print("Scanning directory: $directory");
    $entries = scandir($directory);
    foreach ($entries as $entry) {
        if ($entry === '.' || $entry === '..') continue;
        $path = $directory . '/' . $entry;
        if (is_file($path) && pathinfo($path, PATHINFO_EXTENSION) === 'txt') {
            debug_print("Processing file: $path");
            process_file($path, $messages, $repo_path);
        } elseif (is_dir($path)) {
            scan_directory($path, $messages, $repo_path);
        }
    }
}

function get_commit_timestamp($file_path) {
    $command = "git log -1 --format=%ct -- " . escapeshellarg($file_path);
    $output = trim(shell_exec($command));
    return $output ? (int)$output : time();
}

function read_file_with_encoding($file_path) {
    $content = file_get_contents($file_path);
    $encoding = mb_detect_encoding($content, ['UTF-8', 'ISO-8859-1', 'ASCII'], true);
    return mb_convert_encoding($content, 'UTF-8', $encoding);
}

function process_file($file_path, &$messages, $repo_path) {
    global $DEBUG;
    debug_print("Processing file: $file_path");
    $relative_path = str_replace($repo_path . '/', '', $file_path);

    $commit_timestamp = get_commit_timestamp($file_path);

    try {
        $content = read_file_with_encoding($file_path);
        list($author, $hashtags) = extract_metadata($content);
    } catch (Exception $e) {
        debug_print("Error reading file $file_path: " . $e->getMessage());
        $author = "Error";
        $content = "Error reading message";
        $hashtags = [];
    }

    $content = preg_replace('/author:\s*.+/i', '', $content);
    $content = trim($content);
    debug_print("Processed content. Length: " . strlen($content));

    $messages[] = [
        'author' => $author,
        'content' => $content,
        'timestamp' => $commit_timestamp,
        'hashtags' => $hashtags
    ];
    debug_print("Message added. Total messages: " . count($messages));
}

function generate_chat_html($repo_path, $output_file, $max_messages = 50, $max_message_length = 300, $title = "THIMBLE Chat") {
    debug_print("Generating chat HTML. Repo path: $repo_path, Output file: $output_file");
    
    $HTML_TEMPLATE = read_file('./template/html/chat_page.html');
    $MESSAGE_TEMPLATE = read_file('./template/html/chat_message.html');
    $CSS_STYLE = read_file('./template/css/chat_style.css');
    $JS_TEMPLATE = read_file('./template/js/chat.js');

    $messages = [];
    $message_dir = $repo_path . "/message";
    debug_print("Scanning directory: $message_dir");

    scan_directory($message_dir, $messages, $repo_path);

    debug_print("Sorting messages by timestamp");
    usort($messages, function($a, $b) {
        return $b['timestamp'] - $a['timestamp'];
    });

    // Limit the number of messages
    $messages = array_slice($messages, 0, $max_messages);

    $chat_messages = [];
    foreach ($messages as $idx => $msg) {
        debug_print("Processing message " . ($idx + 1) . "/" . count($messages));
        list($truncated_content, $is_truncated) = truncate_message($msg['content'], $max_message_length);
        $expand_link = $is_truncated ? "<a href=\"#\" class=\"expand-link\" data-message-id=\"$idx\">Show More</a>" : "";
        $full_content = $is_truncated ? "<div class=\"full-message\" id=\"full-message-$idx\" style=\"display: none;\">{$msg['content']}</div>" : '';

        $chat_messages[] = str_replace(
            ['{author}', '{content}', '{full_content}', '{expand_link}', '{timestamp}', '{hashtags}'],
            [$msg['author'], $truncated_content, $full_content, $expand_link, date('Y-m-d H:i:s', $msg['timestamp']), implode(' ', $msg['hashtags'])],
            $MESSAGE_TEMPLATE
        );
    }

    debug_print("Generating final HTML content");
    $html_content = str_replace(
        ['{style}', '{chat_messages}', '{message_count}', '{current_time}', '{title}'],
        [$CSS_STYLE, implode('', $chat_messages), count($messages), date('Y-m-d H:i:s'), $title],
        $HTML_TEMPLATE
    );

    $html_content = str_replace('</body>', '<script>' . $JS_TEMPLATE . '</script></body>', $html_content);

    debug_print("Writing HTML content to file: $output_file");
    file_put_contents($output_file, $html_content);
}

// Command line argument parsing
$options = getopt("", ["repo_path:", "output_file:", "max_messages:", "max_message_length:", "title:", "debug"]);

$repo_path = $options['repo_path'] ?? '.';
$output_file = $options['output_file'] ?? 'chat.html';
$max_messages = $options['max_messages'] ?? 50;
$max_message_length = $options['max_message_length'] ?? 300;
$title = $options['title'] ?? 'THIMBLE Chat';
$DEBUG = isset($options['debug']);

generate_chat_html($repo_path, $output_file, $max_messages, $max_message_length, $title);
debug_print("Chat log generated: $output_file");
debug_print("Script completed.");
?>
