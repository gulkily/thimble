#!/usr/bin/env perl

# fix_indent.pl v2
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

	my $lines_changed = 0;

	# Detect the most common space indentation
	my @space_indents = $content =~ /^( +)/mg;
	if (@space_indents) {
	my %count;
	$count{$_}++ for @space_indents;
	my $most_common_indent = (sort { $count{$b} <=> $count{$a} } keys %count)[0];
	my $spaces_per_indent = length($most_common_indent);

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

	$lines_changed = @lines - @converted_lines;

	# Join the lines and write back to the file
	my $converted_content = join "\n", @converted_lines;
	open $file, '>', $file_path or die "Cannot open file $file_path for writing: $!";
	print $file $converted_content;
	close $file;
	}

	return $lines_changed;
}

sub process_directory {
	my ($directory) = @_;

	find(
	{
	    wanted => sub {
		return unless -f;
		return unless /\.(py|js|html|php|pl|rb|css)$/;
		my $file_path = $File::Find::name;
		my $lines_changed = convert_spaces_to_tabs($file_path);
		if ($lines_changed > 0) {
		    print "Converted $lines_changed lines in $file_path\n";
		}
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

# end of fix_indent.pl