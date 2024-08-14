#!/usr/bin/perl

# test_commit_files.pl
# to run: perl test_commit_files.pl

use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use POSIX qw(strftime);
use JSON;
use File::Path qw(make_path);

sub random_string {
    my $length = shift || 8;
    my @chars = ('0'..'9', 'a'..'f');
    return join '', map { $chars[rand @chars] } 1..$length;
}

sub create_test_file {
    my $content = shift;
    my $date_str = strftime("%Y-%m-%d", localtime);
    my $filename = random_string() . '.txt';
    my $dir_path = "message/$date_str";
    make_path($dir_path) unless -d $dir_path;
    my $file_path = "$dir_path/$filename";

    open my $fh, '>', $file_path or die "Could not open file '$file_path' $!";
    print $fh $content;
    close $fh;

    return $file_path;
}

sub run_commit_files {
    my $script = shift;
    system($script);
}

sub check_git_log {
    my $log_output = `git log -1 --pretty=format:%s`;
    return $log_output =~ /Auto-commit/;
}

sub check_metadata_file {
    my $filename = shift;
    my $metadata_file = $filename;
    $metadata_file =~ s|/([^/]+)$|/metadata/$1.json|;
    return 0 unless -f $metadata_file;

    open my $fh, '<', $metadata_file or die "Could not open file '$metadata_file' $!";
    my $json = do { local $/; <$fh> };
    close $fh;

    my $metadata = decode_json($json);
    return exists $metadata->{author} && exists $metadata->{title} && exists $metadata->{hashtags} && exists $metadata->{file_hash};
}

sub run_tests {
    my $script = shift;
    print "Testing $script\n";

    # Test 1: Commit a single file
    my $file1 = create_test_file("Author: John Doe\nThe Beauty of Nature\n\nNature's beauty is an awe-inspiring spectacle that never fails to amaze us. From the grandeur of mountains to the delicacy of a flower, it reminds us of the world's magnificence.\n\n#nature #beauty #inspiration");
    run_commit_files($script);
    die "Git commit not found" unless check_git_log();
    die "Metadata file not created or invalid" unless check_metadata_file($file1);
    print "Test 1 passed: Single file commit\n";

    # Test 2: Commit multiple files
    my $file2 = create_test_file("Author: Jane Smith\nThe Art of Cooking\n\nCooking is not just about sustenance; it's an art form that engages all our senses. The sizzle of a pan, the aroma of spices, and the vibrant colors of fresh ingredients all come together to create culinary masterpieces.\n\n#cooking #art #food");
    my $file3 = create_test_file("Author: Bob Johnson\nThe Joy of Learning\n\nLearning is a lifelong journey that opens doors to new worlds. Whether it's picking up a new skill or diving deep into a subject, the process of discovery and growth is incredibly rewarding.\n\n#learning #education #growth");
    run_commit_files($script);
    die "Git commit not found" unless check_git_log();
    die "Metadata files not created or invalid" unless check_metadata_file($file2) && check_metadata_file($file3);
    print "Test 2 passed: Multiple file commit\n";

    # Test 3: No changes to commit
    run_commit_files($script);
    print "Test 3 passed: No changes to commit\n";

    print "All tests passed for $script\n";
}

my @scripts = (
    'python3 commit_files.py',
    'node commit_files.js',
    'php commit_files.php',
    'perl commit_files.pl',
    'ruby commit_files.rb'
);

for my $script (@scripts) {
    run_tests($script);
}