#!/usr/bin/env perl

# upgrade_from_repo.pl
# to run: perl upgrade_from_repo.pl <repository_path>

use strict;
use warnings;
use Cwd;

sub run_command {
    my $command = shift;
    my $output = `$command 2>&1`;
    if ($? != 0) {
        print "Error executing command: $command\n";
        print "Error message: $output\n";
        return undef;
    }
    chomp $output;
    return $output;
}

sub is_git_repo {
    return defined run_command("git rev-parse --is-inside-work-tree");
}

my $repo_path = $ARGV[0];
if (!defined $repo_path) {
    print "Usage: $0 <repository_path>\n";
    exit 1;
}

chdir $repo_path or die "Cannot change to directory $repo_path: $!";

if (!is_git_repo()) {
    print "Error: Not a Git repository\n";
    exit 1;
}

# Get the main branch name
my $remote_info = run_command("git remote show origin");
my ($main_branch) = $remote_info =~ /HEAD branch: (\S+)/;

# Checkout the main branch
run_command("git checkout $main_branch");

# Stash any local changes
run_command("git stash");

# Fetch the latest changes
run_command("git fetch origin");

# Reset to the latest commit on the main branch
run_command("git reset --hard origin/$main_branch");

# Clean up untracked files and directories
run_command("git clean -fd");

# Update submodules
run_command("git submodule update --init --recursive");

# Apply stashed changes if any
run_command("git stash pop");

# Verify the repository integrity
run_command("git fsck");

print "Repository updated successfully\n";

# end of upgrade_from_repo.pl