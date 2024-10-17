#!/usr/bin/perl

# chat.html.pl
# to run: perl chat.html.pl
# when editing this file, please retain all the comments and metadata

use strict;
use warnings;
use File::Find;
use File::Spec;
use Time::Local;
use Encode qw(decode);
use Getopt::Long;
use threads;
use Thread::Queue;

my $DEBUG = 0;

sub debug_print {
	print @_, "\n" if $DEBUG;
}

debug_print("Script started.");

sub read_file {
	my ($file_path) = @_;
	open my $file, '<:encoding(UTF-8)', $file_path or die "Cannot open $file_path: $!";
	my $content = do { local $/; <$file> };
	close $file;
	return $content;
}

sub extract_metadata {
	my ($content) = @_;
	my $author = $content =~ /Author:\s*(.+)/i ? $1 : "Unknown";
	my @hashtags = $content =~ /#(\w+)/g;
	return ($author, \@hashtags);
}

sub truncate_message {
	my ($content, $max_length) = @_;
	$max_length //= 300;
	if (length($content) <= $max_length) {
		return ($content, 0);
	}
	return (substr($content, 0, $max_length) . "...", 1);
}

sub process_file {
	my ($file_path) = @_;
	my $modification_time = (stat($file_path))[9];
	my $content = read_file($file_path);
	my ($author, $hashtags) = extract_metadata($content);
	$content =~ s/author:\s*.+//i;
	$content =~ s/^\s+|\s+$//g;
	return {
		author => $author,
		content => $content,
		timestamp => $modification_time,
		hashtags => $hashtags,
		file_path => $file_path
	};
}

sub worker {
	my ($queue, $results) = @_;
	while (my $file_path = $queue->dequeue_nb()) {
		my $message = process_file($file_path);
		$results->enqueue($message);
	}
}

sub generate_chat_html {
	my ($repo_path, $output_file, $max_messages, $max_message_length, $title) = @_;
	$max_messages //= 50;
	$max_message_length //= 300;
	$title //= "THIMBLE Chat";

	debug_print("Generating chat HTML. Repo path: $repo_path, Output file: $output_file");

	my $HTML_TEMPLATE = read_file('./template/html/chat_page.html');
	my $MESSAGE_TEMPLATE = read_file('./template/html/chat_message.html');
	my $CSS_STYLE = read_file('./template/css/chat_style.css');
	my $JS_TEMPLATE = read_file('./template/js/chat.js');

	my $message_dir = File::Spec->catdir($repo_path, "message");
	debug_print("Scanning directory: $message_dir");

	my @file_paths;
	find(
		{
			wanted => sub {
				push @file_paths, $File::Find::name if -f && /\.txt$/;
			},
			no_chdir => 1
		},
		$message_dir
	);

	my $queue = Thread::Queue->new();
	my $results = Thread::Queue->new();
	$queue->enqueue(@file_paths);

	my $num_threads = 4;  # Adjust based on your system
	my @threads = map { threads->create(\&worker, $queue, $results) } 1..$num_threads;
	$queue->enqueue((undef) x $num_threads);  # Signal workers to finish

	$_->join for @threads;

	my @messages;
	while (my $message = $results->dequeue_nb()) {
		push @messages, $message;
	}

	debug_print("Sorting messages by timestamp");
	@messages = sort { $b->{timestamp} <=> $a->{timestamp} } @messages;
	@messages = @messages[0 .. ($max_messages - 1)] if @messages > $max_messages;

	my @chat_messages;
	for my $idx (0 .. $#messages) {
		my $msg = $messages[$idx];
		my ($truncated_content, $is_truncated) = truncate_message($msg->{content}, $max_message_length);
		my $expand_link = $is_truncated ? qq{<a href="#" class="expand-link" data-message-id="$idx">Show More</a>} : "";
		my $full_content = $is_truncated ? qq{<div class="full-message" id="full-message-$idx" style="display: none;">$msg->{content}</div>} : '';

		my $formatted_message = $MESSAGE_TEMPLATE;
		$formatted_message =~ s/\{author\}/$msg->{author}/g;
		$formatted_message =~ s/\{content\}/$truncated_content/g;
		$formatted_message =~ s/\{full_content\}/$full_content/g;
		$formatted_message =~ s/\{expand_link\}/$expand_link/g;
		$formatted_message =~ s/\{timestamp\}/scalar localtime($msg->{timestamp})/ge;
		$formatted_message =~ s/\{hashtags\}/join(' ', @{$msg->{hashtags}})/ge;

		push @chat_messages, $formatted_message;
	}

	debug_print("Generating final HTML content");
	my $html_content = $HTML_TEMPLATE;
	$html_content =~ s/\{style\}/$CSS_STYLE/g;
	$html_content =~ s/\{chat_messages\}/join('', @chat_messages)/ge;
	$html_content =~ s/\{message_count\}/scalar(@messages)/ge;
	$html_content =~ s/\{current_time\}/scalar localtime/ge;
	$html_content =~ s/\{title\}/$title/g;

	$html_content =~ s/<\/body>/<script>$JS_TEMPLATE<\/script><\/body>/;

	debug_print("Writing HTML content to file: $output_file");
	open my $fh, '>:encoding(UTF-8)', $output_file or die "Cannot open $output_file: $!";
	print $fh $html_content;
	close $fh;
}

my ($repo_path, $output_file, $max_messages, $max_message_length, $title);
GetOptions(
	"repo_path=s" => \$repo_path,
	"output_file=s" => \$output_file,
	"max_messages=i" => \$max_messages,
	"max_message_length=i" => \$max_message_length,
	"title=s" => \$title,
	"debug" => \$DEBUG
);

$repo_path //= ".";
$output_file //= "chat.html";
$max_messages //= 50;
$max_message_length //= 300;
$title //= "THIMBLE Chat";

generate_chat_html($repo_path, $output_file, $max_messages, $max_message_length, $title);
debug_print("Chat log generated: $output_file");
debug_print("Script completed.");

# end of chat.html.pl # marker comment, do not remove!