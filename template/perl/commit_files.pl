#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;
use File::Path qw(make_path);
use JSON;
use Digest::SHA qw(sha256_hex);

sub calculate_file_hash {
	my ($file_path) = @_;
	open my $fh, '<', $file_path or die "Can't open '$file_path': $!";
	my $sha = Digest::SHA->new(256);
	$sha->addfile($fh);
	close $fh;
	return $sha->hexdigest;
}

sub extract_metadata {
	my ($content, $file_path) = @_;
	my %metadata = (
		author => '',
		title => basename($file_path),
		hashtags => [],
		file_hash => calculate_file_hash($file_path)
	);

	if ($content =~ /Author:\s*(.+)/m) {
		$metadata{author} = $1;
	}

	if ($content =~ /^(.+)/m) {
		$metadata{title} = $1;
	}

	$metadata{hashtags} = [$content =~ /#(\w+)/g];

	return \%metadata;
}

sub store_metadata {
	my ($file_path, $metadata) = @_;
	my $metadata_dir = dirname($file_path) . '/metadata';
	make_path($metadata_dir);

	my $metadata_file = $metadata_dir . '/' . basename($file_path) . '.json';
	open my $fh, '>', $metadata_file or die "Can't open '$metadata_file': $!";
	print $fh JSON->new->pretty->encode($metadata);
	close $fh;

	return $metadata_file;
}

sub run_git_command {
	my ($command) = @_;
	my $output = `$command 2>&1`;
	return $output;
}

sub commit_text_files {
	my $repo_path = shift || '.';
	chdir $repo_path;

	my $status_output = run_git_command("git status --porcelain");
	if (!$status_output) {
		print "No changes to commit.\n";
		return;
	}

	my $changed_files = run_git_command("git diff --name-only");
	my $untracked_files = run_git_command("git ls-files --others --exclude-standard");

	my @all_files = split(/\n/, $changed_files . $untracked_files);
	my @txt_files = grep { /\.txt$/ } @all_files;

	if (!@txt_files) {
		print "No uncommitted .txt files found.\n";
		return;
	}

	my @metadata_files;
	foreach my $file_path (@txt_files) {
		my $full_path = "$repo_path/$file_path";
		open my $fh, '<', $full_path or die "Can't open '$full_path': $!";
		my $content = do { local $/; <$fh> };
		close $fh;

		my $metadata = extract_metadata($content, $full_path);
		my $metadata_file = store_metadata($full_path, $metadata);
		push @metadata_files, $metadata_file;

		print "File: $file_path\n";
		print "Author: $metadata->{author}\n";
		print "Title: $metadata->{title}\n";
		print "Hashtags: " . join(', ', @{$metadata->{hashtags}}) . "\n";
		print "File Hash: $metadata->{file_hash}\n\n";
	}

	my @files_to_add = (@txt_files, @metadata_files);
	foreach my $file (@files_to_add) {
		run_git_command("git add $file");
	}

	my $commit_message = "Auto-commit " . scalar(@txt_files) . " text files and metadata on " . localtime() . " by commit_files.pl";
	run_git_command(qq{git commit -m "$commit_message"});

	print "Committed " . scalar(@txt_files) . " text files and their metadata.\n";
	print "Commit message: $commit_message\n";
}

commit_text_files();