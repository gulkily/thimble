# start_server.rb
# to run: ruby start_server.rb


# Outline:
# 1. Import required libraries
# 2. Define CustomHTTPHandler class
#    - Handle GET requests
#    - Handle POST requests
#    - Serve text files
#    - Generate and update reports
# 3. Define helper functions
#    - Check port availability
#    - Find available port
#    - Run server
# 4. Parse command-line options
# 5. Start the server

# Functionality:
# This script starts a web server with the following features:
# - Serves static files from a specified directory
# - Handles custom routes for specific pages (/, /log.html, /chat.html)
# - Provides an API endpoint for GitHub updates
# - Serves text files with HTML formatting
# - Handles chat message submissions
# - Automatically generates and updates log and chat HTML files
# - Finds an available port if the specified port is in use
# - Allows customization of port and directory via command-line options

# start_server: v3

require 'webrick'
require 'optparse'
require 'time'
require 'cgi'
require 'uri'
require 'fileutils'
require 'securerandom'

class CustomHTTPHandler < WEBrick::HTTPServlet::FileHandler
  def initialize(server, root)
	super
	@root = root
  end

  def do_GET(req, res)
	case req.path
	when '/'
	  super
	when '/log.html'
	  check_and_generate_report
	  super
	when '/chat.html'
	  check_and_generate_chat_html
	  super
	when '/api/github_update'
	  res.status = 200
	  res['Content-Type'] = 'text/html'
	  res.body = "Update triggered successfully"
	  system('ruby github_update.rb')
	else
	  if req.path.end_with?('.txt')
		serve_text_file(req, res)
	  else
		super
	  end
	end
  end

  def do_POST(req, res)
	if req.path == '/chat.html'
	  handle_chat_post(req, res)
	else
	  res.status = 405
	  res.body = "Method Not Allowed"
	end
  end

  def handle_chat_post(req, res)
	params = CGI.parse(req.body)
	author = params['author']&.first || ''
	message = params['message']&.first || ''

	if !author.empty? && !message.empty?
	  save_message(author, message)
	  res.status = 200
	  res['Content-Type'] = 'text/html'
	  res.body = "Message saved successfully"
	  res.body += '<meta http-equiv="refresh" content="1;url=/chat.html">'
	  system('ruby commit_files.rb message')
	  system('ruby github_update.rb')
	else
	  res.status = 400
	  res.body = "Bad Request: Missing author or message"
	end
  end

  def save_message(author, message)
	today = Time.now.strftime('%Y-%m-%d')
	directory = File.join(@root, 'message', today)
	FileUtils.mkdir_p(directory)

	title = generate_title(message)
	filename = "#{title}.txt"
	filepath = File.join(directory, filename)

	File.open(filepath, 'w', encoding: 'utf-8') do |f|
	  f.puts message
	  f.puts "\n\nauthor: #{author}"
	end
  end

  def generate_title(message)
	words = message.split.take(5)
	title = words.join('_')
	title = title.gsub(/[^0-9A-Za-z_-]/, '')
	title = SecureRandom.alphanumeric(10) if title.empty?
	title
  end

  def check_and_generate_report
	html_file = File.join(@root, 'log.html')
	if !File.exist?(html_file) || Time.now - File.mtime(html_file) > 60
	  puts "#{html_file} is older than 60 seconds or does not exist. Running log.html.rb..."
	  system('ruby log.html.rb')
	else
	  puts "#{html_file} is up-to-date."
	end
  end

  def check_and_generate_chat_html
	chat_html_file = File.join(@root, 'chat.html')
	if !File.exist?(chat_html_file) || Time.now - File.mtime(chat_html_file) > 60
	  puts "#{chat_html_file} is older than 60 seconds or does not exist. Running chat.html.rb..."
	  system('ruby chat.html.rb')
	else
	  puts "#{chat_html_file} is up-to-date."
	end
  end

  def serve_text_file(req, res)
	path = File.join(@root, req.path)
	if File.exist?(path)
	  content = File.read(path, encoding: 'utf-8')
	  res.body = <<~HTML
		<!DOCTYPE html>
		<html lang="en">
		<head>
			<meta charset="UTF-8">
			<meta name="viewport" content="width=device-width, initial-scale=1.0">
			<title>#{File.basename(path)}</title>
			<style>
				body { font-family: Arial, sans-serif; line-height: 1.6; padding: 20px; }
				pre { background-color: #f4f4f4; padding: 15px; border-radius: 5px; white-space: pre-wrap; word-wrap: break-word; }
			</style>
		</head>
		<body>
			<h1>#{File.basename(path)}</h1>
			<pre>#{CGI.escapeHTML(content)}</pre>
		</body>
		</html>
	  HTML
	  res.content_type = 'text/html'
	else
	  raise WEBrick::HTTPStatus::NotFound
	end
  end
end

def is_port_in_use?(port)
  TCPServer.new('localhost', port).close
  false
rescue Errno::EADDRINUSE
  true
end

def find_available_port(start_port)
  port = start_port
  port += 1 while is_port_in_use?(port)
  port
end

def run_server(port, directory)
  Dir.chdir(directory)
  server = WEBrick::HTTPServer.new(Port: port, DocumentRoot: directory)
  server.mount('/', CustomHTTPHandler, directory)

  trap('INT') do
	puts "\nShutting down server..."
	server.shutdown
  end

  puts "Serving HTTP on 0.0.0.0 port #{port} (http://0.0.0.0:#{port}/) ..."
  server.start
rescue Errno::EADDRINUSE
  puts "Port #{port} is already in use."
  false
end

if __FILE__ == $PROGRAM_NAME
  options = {}
  OptionParser.new do |opts|
	opts.banner = "Usage: ruby script.rb [options]"
	opts.on("-p", "--port PORT", Integer, "Port to serve on (default: 8000)") { |p| options[:port] = p }
	opts.on("-d", "--directory DIR", String, "Directory to serve (default: current directory)") { |d| options[:directory] = d }
  end.parse!

  directory = options[:directory] || Dir.pwd

  if options[:port]
	if is_port_in_use?(options[:port])
	  puts "Port #{options[:port]} is already in use. Please choose a different port."
	else
	  run_server(options[:port], directory)
	end
  else
	port = 8000
	port = find_available_port(port) if is_port_in_use?(port)
	run_server(port, directory)
  end
end

# end of start_server.rb