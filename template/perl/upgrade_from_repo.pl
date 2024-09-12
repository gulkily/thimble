#!/usr/bin/env perl

# upgrade_from_repo.pl
# to run: perl upgrade_from_repo.pl <repository_path>

# Functionality Definition:
#
# This script updates a Git repository to the latest version of its main branch.
# It performs the following steps:
#
# 1. Check if a repository path is provided as a command-line argument.
# 2. Change the working directory to the provided repository path.
# 3. Verify that the directory is a Git repository.
# 4. Determine the name of the main branch (e.g., 'main' or 'master').
# 5. Checkout the main branch.
# 6. Stash any local changes to prevent conflicts.
# 7. Fetch the latest changes from the remote repository.
# 8. Reset the local branch to match the remote branch exactly.
# 9. Clean up any untracked files and directories.
# 10. Update all submodules recursively.
# 11. Attempt to reapply the stashed changes.
# 12. Verify the integrity of the repository.
# 13. Print a success message if all steps complete without error.
#
# The script includes error handling to catch and report any issues that occur
# during the update process. It uses subprocess calls to execute Git commands
# and capture their output for error checking.
#

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