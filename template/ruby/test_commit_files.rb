# test_commit_files.rb
# to run: ruby test_commit_files.rb

require 'fileutils'
require 'json'
require 'securerandom'
require 'date'

def random_string(length=8)
	SecureRandom.alphanumeric(length)
end

def create_test_file(content)
	date_str = Date.today.strftime("%Y-%m-%d")
	filename = "#{random_string}.txt"
	dir_path = File.join("message", date_str)
	FileUtils.mkdir_p(dir_path)
	file_path = File.join(dir_path, filename)

	File.write(file_path, content)

	file_path
end

def run_commit_files(script)
	system(script)
end

def check_git_log
	`git log -1 --pretty=format:%s`.include?("Auto-commit")
end

def check_metadata_file(filename)
	metadata_file = File.join(File.dirname(filename), "metadata", "#{File.basename(filename)}.json")
	return false unless File.exist?(metadata_file)
	metadata = JSON.parse(File.read(metadata_file))
	['author', 'title', 'hashtags', 'file_hash'].all? { |key| metadata.key?(key) }
end

def run_tests(script)
	puts "Testing #{script}"

	# Test 1: Commit a single file
	file1 = create_test_file("Author: John Doe\nThe Beauty of Nature\n\nNature's beauty is an awe-inspiring spectacle that never fails to amaze us. From the grandeur of mountains to the delicacy of a flower, it reminds us of the world's magnificence.\n\n#nature #beauty #inspiration")
	run_commit_files(script)
	raise "Git commit not found" unless check_git_log
	raise "Metadata file not created or invalid" unless check_metadata_file(file1)
	puts "Test 1 passed: Single file commit"

	# Test 2: Commit multiple files
	file2 = create_test_file("Author: Jane Smith\nThe Art of Cooking\n\nCooking is not just about sustenance; it's an art form that engages all our senses. The sizzle of a pan, the aroma of spices, and the vibrant colors of fresh ingredients all come together to create culinary masterpieces.\n\n#cooking #art #food")
	file3 = create_test_file("Author: Bob Johnson\nThe Joy of Learning\n\nLearning is a lifelong journey that opens doors to new worlds. Whether it's picking up a new skill or diving deep into a subject, the process of discovery and growth is incredibly rewarding.\n\n#learning #education #growth")
	run_commit_files(script)
	raise "Git commit not found" unless check_git_log
	raise "Metadata files not created or invalid" unless check_metadata_file(file2) && check_metadata_file(file3)
	puts "Test 2 passed: Multiple file commit"

	# Test 3: No changes to commit
	run_commit_files(script)
	puts "Test 3 passed: No changes to commit"

	puts "All tests passed for #{script}"
end

if __FILE__ == $0
	scripts = [
		"python3 commit_files.py",
		"node commit_files.js",
		"php commit_files.php",
		"perl commit_files.pl",
		"ruby commit_files.rb"
	]

	scripts.each do |script|
		run_tests(script)
	end
end