#!/usr/bin/env perl

# fix_indent.pl
# to use: perl fix_indent.pl <directory>

use strict;
use warnings;
use File::Find;
use File::Spec;

sub convert_spaces_to_tabs {
	my ($file_path) = @_;

	# Read the file content
	open my $file, '<', $file_path or die "Cannot open file $file_path: $!";
	my $content = do { local $/; <$file> };
	close $file;

	# Detect the most common space indentation
	my @space_indents = $content =~ /^( +)/mg;
	my $spaces_per_indent = 4;  # Default to 4 spaces if no indentation is found

	if (@space_indents) {
		my %count;
		$count{$_}++ for @space_indents;
		my $most_common_indent = (sort { $count{$b} <=> $count{$a} } keys %count)[0];
		$spaces_per_indent = length($most_common_indent);
	}

	# Replace space indentation with tabs
	my @lines = split /\n/, $content;
	my @converted_lines;

	for my $line (@lines) {
		my $indent_count = 0;
		while ($line =~ s/^( {$spaces_per_indent})//) {
			$indent_count++;
		}
		push @converted_lines, ("\t" x $indent_count) . $line;
	}

	# Join the lines and write back to the file
	my $converted_content = join "\n", @converted_lines;
	open $file, '>', $file_path or die "Cannot open file $file_path for writing: $!";
	print $file $converted_content;
	close $file;
}

sub process_directory {
	my ($directory) = @_;

	find(
		{
			wanted => sub {
				return unless -f;
				return unless /\.(py|js|txt|html|php|pl|rb|css)$/;
				my $file_path = $File::Find::name;
				print "Converting space indentation to tabs in: $file_path\n";
				convert_spaces_to_tabs($file_path);
			},
			no_chdir => 1,
		},
		$directory
	);
}

if (@ARGV != 1) {
	die "Usage: perl fix_indent.pl <directory>\n";
}

my $directory = $ARGV[0];
unless (-d $directory) {
	die "Error: $directory is not a valid directory\n";
}

process_directory($directory);
print "Indentation conversion complete.\n";