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
	curr_dir = Dir.pwd
	repo_path = File.expand_path(repo_path)
	Dir.chdir(repo_path)

	begin
		# Get modified and untracked files
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
			begin
				abs_path = File.join(repo_path, file_path)
				content = File.read(abs_path, encoding: 'UTF-8')
				metadata = extract_metadata(content, abs_path)
				metadata_file = store_metadata(abs_path, metadata)

				puts "File: #{file_path}"
				puts "Author: #{metadata['author']}"
				puts "Title: #{metadata['title']}"
				puts "Hashtags: #{metadata['hashtags'].join(', ')}"
				puts "File Hash: #{metadata['file_hash']}"
				puts

				rel_metadata = metadata_file.sub("#{repo_path}/", '')
				run_git_command("git add '#{file_path}' '#{rel_metadata}'")
				metadata_files << rel_metadata
			rescue => e
				puts "Error processing file #{file_path}: #{e.message}"
			end
		end

		# Create commit
		timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
		commit_message = "Auto-commit #{txt_files.size} text files and metadata on #{timestamp} by commit_files.rb"
		run_git_command("git commit -m '#{commit_message}'")

		puts "Committed #{txt_files.size} text files and their metadata."
		puts "Commit message: #{commit_message}"
	rescue => e
		puts "Error: #{e.message}"
	ensure
		Dir.chdir(curr_dir)
	end
end

if __FILE__ == $0
	commit_text_files
end