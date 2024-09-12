#!/usr/bin/env ruby

# fix_indent.rb v2
# to use: ruby fix_indent.rb <directory>

require 'find'

def convert_spaces_to_tabs(file_path)
	# Read the file content
	content = File.read(file_path)

	lines_changed = 0

	# Detect the most common space indentation
	space_indents = content.scan(/^( +)/)
	if !space_indents.empty?
	count = Hash.new(0)
	space_indents.each { |indent| count[indent[0]] += 1 }
	most_common_indent = count.max_by { |_, v| v }[0]
	spaces_per_indent = most_common_indent.length

	# Replace space indentation with tabs
	lines = content.split("\n")
	converted_lines = lines.map do |line|
	  indent_count = 0
	  while line.sub!(/^#{' ' * spaces_per_indent}/, '')
		indent_count += 1
	  end
	  "\t" * indent_count + line
	end

	lines_changed = lines.size - converted_lines.size

	# Join the lines and write back to the file
	converted_content = converted_lines.join("\n")
	File.write(file_path, converted_content)
	end

	lines_changed
end

def process_directory(directory)
	Find.find(directory) do |path|
	next unless File.file?(path)
	next unless path =~ /\.(py|js|html|php|pl|rb|css)$/
	lines_changed = convert_spaces_to_tabs(path)
	puts "Converted #{lines_changed} lines in #{path}" if lines_changed > 0
	end
end

if ARGV.size != 1
	puts "Usage: ruby fix_indent.rb <directory>"
	exit 1
end

directory = ARGV[0]
unless File.directory?(directory)
	puts "Error: #{directory} is not a valid directory"
	exit 1
end

process_directory(directory)
puts "Indentation conversion complete."

# end of fix_indent.rb