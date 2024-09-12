#!/usr/bin/perl

# start_server.pl
# to run: perl start_server.pl

# start_server: v3

use strict;
use warnings;
use HTTP::Daemon;
use HTTP::Status;
use HTTP::Response;
use File::Spec;
use File::Basename;
use Getopt::Long;
use POSIX qw(strftime);
use Cwd;
use Socket;
use URI::Escape;

my $port = 8000;
my $directory = getcwd();

GetOptions(
	"port|p=i" => \$port,
	"directory|d=s" => \$directory
) or die "Usage: $0 [-p|--port PORT] [-d|--directory DIR]\n";

chdir $directory or die "Cannot change to directory $directory: $!";

sub is_port_in_use {
	my ($port) = @_;
	my $sock;
	my $in_use = 0;

	socket($sock, PF_INET, SOCK_STREAM, getprotobyname('tcp')) or die "socket: $!";
	if (connect($sock, sockaddr_in($port, inet_aton('127.0.0.1')))) {
		$in_use = 1;
	}
	close($sock);

	return $in_use;
}

sub find_available_port {
	my ($start_port) = @_;
	my $port = $start_port;
	while (is_port_in_use($port)) {
		$port++;
	}
	return $port;
}

sub run_server {
	my ($port) = @_;

	my $d = HTTP::Daemon->new(
		LocalAddr => '0.0.0.0',
		LocalPort => $port,
		ReuseAddr => 1,
	) or die "Cannot create server: $!";

	print "Serving HTTP on 0.0.0.0 port $port (http://0.0.0.0:$port/) ...\n";

	while (my $c = $d->accept) {
		while (my $r = $c->get_request) {
			handle_request($c, $r);
		}
		$c->close;
		undef($c);
	}
}

sub handle_request {
	my ($c, $r) = @_;

	if ($r->method eq 'GET') {
		if ($r->uri->path eq '/') {
			serve_file($c, 'index.html');
		} elsif ($r->uri->path eq '/log.html') {
			check_and_generate_report();
			serve_file($c, 'log.html');
		} elsif ($r->uri->path eq '/chat.html') {
			check_and_generate_chat_html();
			serve_file($c, 'chat.html');
		} elsif ($r->uri->path eq '/api/github_update') {
			handle_github_update($c);
		} elsif ($r->uri->path =~ /\.txt$/) {
			serve_text_file($c, $r->uri->path);
		} else {
			serve_file($c, $r->uri->path);
		}
	} elsif ($r->method eq 'POST' && $r->uri->path eq '/chat.html') {
		handle_chat_post($c, $r);
	} else {
		$c->send_error(RC_METHOD_NOT_ALLOWED);
	}
}

sub check_and_generate_report {
	my $html_file = File::Spec->catfile($directory, 'log.html');
	if (!-e $html_file || time() - (stat($html_file))[9] > 60) {
		print "$html_file is older than 60 seconds or does not exist. Running log.html.py...\n";
		system('python log.html.py');
	} else {
		print "$html_file is up-to-date.\n";
	}
}

sub check_and_generate_chat_html {
	my $chat_html_file = File::Spec->catfile($directory, 'chat.html');
	if (!-e $chat_html_file || time() - (stat($chat_html_file))[9] > 60) {
		print "$chat_html_file is older than 60 seconds or does not exist. Running chat.html.py...\n";
		system('python chat.html.py');
	} else {
		print "$chat_html_file is up-to-date.\n";
	}
}

sub handle_github_update {
	my ($c) = @_;
	$c->send_response(HTTP::Response->new(RC_OK, 'OK', ['Content-Type' => 'text/html'], "Update triggered successfully"));
	system('python github_update.py');
}

sub handle_chat_post {
	my ($c, $r) = @_;

	my $content = $r->content;
	my %params = map { split /=/, $_, 2 } split /&/, $content;
	my $author = uri_unescape($params{author} || '');
	my $message = uri_unescape($params{message} || '');

	if ($author && $message) {
		save_message($author, $message);
		$c->send_response(HTTP::Response->new(RC_OK, 'OK', ['Content-Type' => 'text/html'],
			"Message saved successfully" . '<meta http-equiv="refresh" content="1;url=chat.html">'));
		system('python commit_files.py message');
		system('python github_update.py');
	} else {
		$c->send_error(RC_BAD_REQUEST, "Bad Request: Missing author or message");
	}
}

sub save_message {
	my ($author, $message) = @_;

	my $today = strftime("%Y-%m-%d", localtime);
	my $dir = File::Spec->catdir($directory, 'message', $today);
	mkdir $dir unless -d $dir;

	my $title = generate_title($message);
	my $filename = "$title.txt";
	my $filepath = File::Spec->catfile($dir, $filename);

	open my $fh, '>', $filepath or die "Cannot open $filepath: $!";
	print $fh "$message\n\nauthor: $author";
	close $fh;
}

sub generate_title {
	my ($message) = @_;
	my @words = split /\s+/, $message;
	my $title = join '_', @words[0..4];
	$title =~ s/[^a-zA-Z0-9_-]//g;
	$title = substr(rand() . rand(), 2, 10) if $title eq '';
	return $title;
}

sub serve_file {
	my ($c, $path) = @_;
	$path =~ s/^\/+//;
	my $file = File::Spec->catfile($directory, $path);

	if (-f $file) {
		open my $fh, '<', $file or die "Cannot open $file: $!";
		my $content = do { local $/; <$fh> };
		close $fh;

		my $content_type = get_content_type($file);
		$c->send_response(HTTP::Response->new(RC_OK, 'OK', ['Content-Type' => $content_type], $content));
	} else {
		$c->send_error(RC_NOT_FOUND);
	}
}

sub serve_text_file {
	my ($c, $path) = @_;
	$path =~ s/^\/+//;
	my $file = File::Spec->catfile($directory, $path);

	if (-f $file) {
		open my $fh, '<', $file or die "Cannot open $file: $!";
		my $content = do { local $/; <$fh> };
		close $fh;

		my $html_content = generate_html_for_text_file(basename($file), $content);
		$c->send_response(HTTP::Response->new(RC_OK, 'OK', ['Content-Type' => 'text/html; charset=utf-8'], $html_content));
	} else {
		$c->send_error(RC_NOT_FOUND);
	}
}

sub generate_html_for_text_file {
	my ($filename, $content) = @_;
	$content =~ s/&/&amp;/g;
	$content =~ s/</&lt;/g;
	$content =~ s/>/&gt;/g;
	return <<HTML;
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>$filename</title>
	<style>
		body { font-family: Arial, sans-serif; line-height: 1.6; padding: 20px; }
		pre { background-color: #f4f4f4; padding: 15px; border-radius: 5px; white-space: pre-wrap; word-wrap: break-word; }
	</style>
</head>
<body>
	<h1>$filename</h1>
	<pre>$content</pre>
</body>
</html>
HTML
}

sub get_content_type {
	my ($file) = @_;
	my %mime_types = (
		'txt' => 'text/plain',
		'html' => 'text/html',
		'css' => 'text/css',
		'js' => 'application/javascript',
		'json' => 'application/json',
		'png' => 'image/png',
		'jpg' => 'image/jpeg',
		'gif' => 'image/gif',
	);
	my ($ext) = $file =~ /\.([^.]+)$/;
	return $mime_types{lc $ext} || 'application/octet-stream';
}

if (is_port_in_use($port)) {
	print "Port $port is already in use.\n";
	$port = find_available_port($port + 1);
	print "Trying port $port...\n";
}

run_server($port);

# end of start_server.pl