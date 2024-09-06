#!/usr/bin/env ruby
# github_update.rb
# to run: ruby github_update.rb [--debug]

require 'open3'
require 'optparse'

DEBUG = false

def debug_print(message)
  puts "DEBUG: #{message}" if DEBUG
end

def run_git_command(command)
  debug_print("Running command: #{command}")
  output, error, status = Open3.capture3(command)
  debug_print("Command output: #{output.strip}")
  debug_print("Command error: #{error.strip}")
  [output.strip, error.strip]
end

def check_for_uncommitted_changes
  puts "Checking for uncommitted changes..."
  status_output, _ = run_git_command("git status --porcelain")
  if status_output.empty?
    puts "No uncommitted changes."
    false
  else
    puts "Uncommitted changes found."
    true
  end
end

def stash_changes
  puts "Stashing local changes..."
  output, error = run_git_command("git stash")
  if output.include?("No local changes to save")
    puts "No changes to stash."
  elsif !error.empty?
    puts "Error stashing changes: #{error}"
    exit(1)
  else
    puts "Changes stashed successfully."
  end
end

def pop_stashed_changes
  puts "Applying stashed changes..."
  output, error = run_git_command("git stash pop")
  if error.include?("No stash entries found")
    puts "No stashed changes to apply."
  elsif !error.empty? && !error.include?("CONFLICT")
    puts "Error applying stashed changes: #{error}"
    exit(1)
  elsif error.include?("CONFLICT")
    puts "Conflicts occurred while applying stashed changes. Please resolve manually."
  else
    puts "Stashed changes applied successfully."
  end
end

def fetch_remote
  puts "Fetching remote changes..."
  _, error = run_git_command("git fetch")
  if !error.empty?
    puts "Error fetching remote: #{error}"
    exit(1)
  end
  puts "Remote changes fetched successfully."
end

def check_for_diverged_history
  puts "Checking for diverged history..."
  local_commit, _ = run_git_command("git rev-parse HEAD")
  remote_commit, _ = run_git_command("git rev-parse @{u}")
  diverged = local_commit != remote_commit
  if diverged
    puts "Local and remote histories have diverged."
  else
    puts "Local and remote histories are in sync."
  end
  diverged
end

def merge_remote_changes
  puts "Merging remote changes..."
  output, error = run_git_command("git merge origin/main")
  if output.include?("CONFLICT") || error.include?("CONFLICT")
    puts "Merge conflict detected. Please resolve conflicts manually."
    exit(1)
  elsif !error.empty?
    puts "Error merging changes: #{error}"
    exit(1)
  else
    puts "Remote changes merged successfully."
  end
end

def push_changes
  puts "Pushing local changes to remote..."
  _, error = run_git_command("git push")
  if !error.empty?
    puts "Error pushing changes: #{error}"
    exit(1)
  end
  puts "Local changes pushed successfully."
end

def github_update
  # Check for uncommitted changes
  stashed = if check_for_uncommitted_changes
              stash_changes
              true
            else
              false
            end

  # Fetch remote changes
  fetch_remote

  # Check for diverged history
  merge_remote_changes if check_for_diverged_history

  # Push local changes
  push_changes

  # Apply stashed changes if any
  pop_stashed_changes if stashed

  puts "GitHub repository updated successfully."
end

if __FILE__ == $PROGRAM_NAME
  OptionParser.new do |opts|
    opts.banner = "Usage: ruby github_update.rb [options]"
    opts.on("--debug", "Enable debug output") do
      DEBUG = true
    end
  end.parse!

  github_update
end
