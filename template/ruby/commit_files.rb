#!/usr/bin/env ruby

# commit_files.rb
# to run: ruby commit_files.rb

require 'fileutils'
require 'json'
require 'digest'
require 'time'

def calculate_file_hash(file_path)
	Digest::SHA256.file(file_path).hexdigest
end

def extract_metadata(content, file_path)
	metadata = {
		'author' => '',
		'title' => File.basename(file_path),
		'hashtags' => [],
		'file_hash' => calculate_file_hash(file_path)
	}

	# Extract author
	author_match = content.match(/Author:\s*(.+)/)
	metadata['author'] = author_match[1].strip if author_match

	# Extract title (assuming it's the first line of the file)
	title_match = content.match(/^(.+)/)
	metadata['title'] = title_match[1].strip if title_match

	# Extract hashtags
	metadata['hashtags'] = content.scan(/#\w+/)

	metadata
end

def store_metadata(file_path, metadata)
	metadata_dir = File.join(File.dirname(file_path), 'metadata')
	FileUtils.mkdir_p(metadata_dir)

	metadata_file = File.join(metadata_dir, "#{File.basename(file_path)}.json")

	File.write(metadata_file, JSON.pretty_generate(metadata))

	metadata_file
end

def run_git_command(command)
	output = `#{command} 2>&1`
	[output.strip, $?.success?]
end

def commit_text_files(repo_path = ".")
	Dir.chdir(repo_path)

	# Check if there are any changes
	status_output, status_success = run_git_command("git status --porcelain")
	if status_output.empty?
		puts "No changes to commit."
		return
	end

	# Get all modified and untracked files
	changed_files, _ = run_git_command("git diff --name-only")
	untracked_files, _ = run_git_command("git ls-files --others --exclude-standard")

	all_files = changed_files.split("\n") + untracked_files.split("\n")
	txt_files = all_files.select { |f| f.end_with?('.txt') }

	if txt_files.empty?
		puts "No uncommitted .txt files found."
		return
	end

	# Process each file and store metadata
	metadata_files = []
	txt_files.each do |file_path|
		full_path = File.join(repo_path, file_path)
		begin
			content = File.read(full_path, encoding: 'UTF-8')

			metadata = extract_metadata(content, full_path)
			metadata_file = store_metadata(full_path, metadata)
			metadata_files << metadata_file

			puts "File: #{file_path}"
			puts "Author: #{metadata['author']}"
			puts "Title: #{metadata['title']}"
			puts "Hashtags: #{metadata['hashtags'].join(', ')}"
			puts "File Hash: #{metadata['file_hash']}"
			puts
		rescue => e
			puts "Error processing file #{file_path}: #{e.message}"
		end
	end

	# Add all .txt files and metadata files to staging
	files_to_add = txt_files + metadata_files
	files_to_add.each do |file|
		run_git_command("git add #{file}")
	end

	# Create commit message
	commit_message = "Auto-commit #{txt_files.size} text files and metadata on #{Time.now.strftime('%Y-%m-%d %H:%M:%S')} by commit_files.rb"

	# Commit the changes
	commit_output, commit_success = run_git_command(%Q{git commit -m "#{commit_message}"})

	if commit_success
		puts "Committed #{txt_files.size} text files and their metadata."
		puts "Commit message: #{commit_message}"
	else
		puts "Failed to commit changes: #{commit_output}"
	end
end

if __FILE__ == $0
	commit_text_files
end