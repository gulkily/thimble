#!/usr/bin/env perl
# github_update.pl
# to run: perl github_update.pl [--debug]

use strict;
use warnings;
use Getopt::Long;
use File::Basename;

my $DEBUG = 0;

sub debug_print {
    my ($message) = @_;
    print "DEBUG: $message\n" if $DEBUG;
}

sub run_git_command {
    my ($command) = @_;
    debug_print("Running command: $command");
    my $output = `$command 2>&1`;
    my $exit_code = $? >> 8;
    debug_print("Command output: $output");
    debug_print("Command exit code: $exit_code");
    return ($output, $exit_code);
}

sub check_for_uncommitted_changes {
    print "Checking for uncommitted changes...\n";
    my ($status_output, $exit_code) = run_git_command("git status --porcelain");
    if ($status_output) {
        print "Uncommitted changes found.\n";
    } else {
        print "No uncommitted changes.\n";
    }
    return $status_output ? 1 : 0;
}

sub stash_changes {
    print "Stashing local changes...\n";
    my ($output, $exit_code) = run_git_command("git stash");
    if ($output =~ /No local changes to save/) {
        print "No changes to stash.\n";
    } elsif ($exit_code != 0) {
        print "Error stashing changes: $output\n";
        exit 1;
    } else {
        print "Changes stashed successfully.\n";
    }
}

sub pop_stashed_changes {
    print "Applying stashed changes...\n";
    my ($output, $exit_code) = run_git_command("git stash pop");
    if ($output =~ /No stash entries found/) {
        print "No stashed changes to apply.\n";
    } elsif ($exit_code != 0 && $output !~ /CONFLICT/) {
        print "Error applying stashed changes: $output\n";
        exit 1;
    } elsif ($output =~ /CONFLICT/) {
        print "Conflicts occurred while applying stashed changes. Please resolve manually.\n";
    } else {
        print "Stashed changes applied successfully.\n";
    }
}

sub fetch_remote {
    print "Fetching remote changes...\n";
    my ($output, $exit_code) = run_git_command("git fetch");
    if ($exit_code != 0) {
        print "Error fetching remote: $output\n";
        exit 1;
    }
    print "Remote changes fetched successfully.\n";
}

sub check_for_diverged_history {
    print "Checking for diverged history...\n";
    my ($local_commit, $exit_code) = run_git_command("git rev-parse HEAD");
    my ($remote_commit, $exit_code2) = run_git_command("git rev-parse \@{u}");
    chomp($local_commit, $remote_commit);
    my $diverged = $local_commit ne $remote_commit;
    if ($diverged) {
        print "Local and remote histories have diverged.\n";
    } else {
        print "Local and remote histories are in sync.\n";
    }
    return $diverged;
}

sub merge_remote_changes {
    print "Merging remote changes...\n";
    my ($output, $exit_code) = run_git_command("git merge origin/main");
    if ($output =~ /CONFLICT/) {
        print "Merge conflict detected. Please resolve conflicts manually.\n";
        exit 1;
    } elsif ($exit_code != 0) {
        print "Error merging changes: $output\n";
        exit 1;
    } else {
        print "Remote changes merged successfully.\n";
    }
}

sub push_changes {
    print "Pushing local changes to remote...\n";
    my ($output, $exit_code) = run_git_command("git push");
    if ($exit_code != 0) {
        print "Error pushing changes: $output\n";
        exit 1;
    }
    print "Local changes pushed successfully.\n";
}

sub github_update {
    my $stashed = 0;
    if (check_for_uncommitted_changes()) {
        stash_changes();
        $stashed = 1;
    }

    fetch_remote();

    if (check_for_diverged_history()) {
        merge_remote_changes();
    }

    push_changes();

    if ($stashed) {
        pop_stashed_changes();
    }

    print "GitHub repository updated successfully.\n";
}

GetOptions("debug" => \$DEBUG) or die("Error in command line arguments\n");

github_update();
