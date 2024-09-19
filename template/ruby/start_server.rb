#!/usr/bin/env ruby

# start_server.rb
# to run: ruby start_server.rb

# start_server: v4

require 'webrick'
require 'optparse'
require 'fileutils'
require 'uri'
require 'cgi'
require 'date'
require 'socket'

class CustomHTTPServer < WEBrick::HTTPServlet::AbstractServlet
  def initialize(server, directory)
    super(server)
    @directory = directory
  end

  def do_GET(request, response)
    case request.path
    when '/'
      serve_file(response, 'index.html')
    when '/log.html'
      check_and_generate_report
      serve_file(response, 'log.html')
    when '/chat.html'
      check_and_generate_chat_html
      serve_file(response, 'chat.html')
    when '/api/github_update'
      handle_github_update(response)
    when /\.txt$/
      serve_text_file(response, request.path)
    else
      serve_file(response, request.path[1..-1])
    end
  end

  def do_POST(request, response)
    if request.path == '/chat.html'
      handle_chat_post(request, response)
    else
      response.status = 405
      response.body = "Method Not Allowed"
    end
  end

  private

  def check_and_generate_report
    html_file = File.join(@directory, 'log.html')
    if !File.exist?(html_file) || Time.now - File.mtime(html_file) > 60
      puts "#{html_file} is older than 60 seconds or does not exist. Running log.html.rb..."
      run_script('log.html')
    else
      puts "#{html_file} is up-to-date."
    end
  end

  def check_and_generate_chat_html
    chat_html_file = File.join(@directory, 'chat.html')
    if !File.exist?(chat_html_file) || Time.now - File.mtime(chat_html_file) > 60
      puts "#{chat_html_file} is older than 60 seconds or does not exist. Running chat.html.rb..."
      run_script('chat.html')
    else
      puts "#{chat_html_file} is up-to-date."
    end
  end

  def handle_github_update(response)
    response.status = 200
    response.body = "Update triggered successfully"
    run_script('github_update')
  end

  def handle_chat_post(request, response)
    params = CGI.parse(request.body)
    author = CGI.unescape(params['author'].first || '')
    message = CGI.unescape(params['message'].first || '')

    if author.empty? || message.empty?
      response.status = 400
      response.body = "Bad Request: Missing author or message"
    else
      save_message(author, message)
      response.status = 200
      response.content_type = 'text/html'
      response.body = "Message saved successfully" + '<meta http-equiv="refresh" content="1;url=chat.html">'
      run_script('commit_files', 'message')
      run_script('github_update')
    end
  end

  def save_message(author, message)
    today = Date.today.strftime("%Y-%m-%d")
    dir = File.join(@directory, 'message', today)
    FileUtils.mkdir_p(dir)

    title = generate_title(message)
    filename = "#{title}.txt"
    filepath = File.join(dir, filename)

    File.open(filepath, 'w') do |file|
      file.puts "#{message}\n\nauthor: #{author}"
    end
  end

  def generate_title(message)
    title = message.split.first(5).join('_')
    title.gsub!(/[^a-zA-Z0-9_-]/, '')
    title = SecureRandom.hex(5) if title.empty?
    title
  end

  def serve_file(response, filename)
    file_path = File.join(@directory, filename)
    if File.exist?(file_path)
      response.body = File.read(file_path)
      response.content_type = get_content_type(file_path)
      response.status = 200
    else
      response.status = 404
      response.body = "File not found"
    end
  end

  def serve_text_file(response, path)
    file_path = File.join(@directory, path[1..-1])
    if File.exist?(file_path)
      content = File.read(file_path)
      html_content = generate_html_for_text_file(File.basename(file_path), content)
      response.body = html_content
      response.content_type = 'text/html; charset=utf-8'
      response.status = 200
    else
      response.status = 404
      response.body = "File not found"
    end
  end

  def generate_html_for_text_file(filename, content)
    content = CGI.escapeHTML(content)
    <<-HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>#{filename}</title>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; padding: 20px; }
        pre { background-color: #f4f4f4; padding: 15px; border-radius: 5px; white-space: pre-wrap; word-wrap: break-word; }
      </style>
    </head>
    <body>
      <h1>#{filename}</h1>
      <pre>#{content}</pre>
    </body>
    </html>
    HTML
  end

  def get_content_type(file)
    case File.extname(file)
    when '.txt' then 'text/plain'
    when '.html' then 'text/html'
    when '.css' then 'text/css'
    when '.js' then 'application/javascript'
    when '.json' then 'application/json'
    when '.png' then 'image/png'
    when '.jpg', '.jpeg' then 'image/jpeg'
    when '.gif' then 'image/gif'
    else 'application/octet-stream'
    end
  end

  def run_script(script_name, *args)
    script_types = ['py', 'rb', 'pl', 'sh', 'js']
    interpreters = ['python3', 'ruby', 'perl', 'bash', 'node']
    interpreter_map = Hash[script_types.zip(interpreters)]

    found_scripts = Dir.glob("template/*/#{script_name}.*")

    if found_scripts.empty?
      puts "No scripts found for #{script_name}"
      return
    end

    found_scripts.each do |script|
      type = File.extname(script)[1..-1]
      if interpreter_map.key?(type)
        interpreter = interpreter_map[type]
        puts "Running #{script} with #{interpreter}..."
        escaped_args = args.map { |arg| Shellwords.escape(arg) }
        system("#{interpreter} #{script} #{escaped_args.join(' ')}")
      else
        puts "No suitable interpreter found for #{script}"
      end
    end
  end
end

def is_port_in_use?(port)
  begin
    server = TCPServer.new('127.0.0.1', port)
    server.close
    false
  rescue Errno::EADDRINUSE
    true
  end
end

def find_available_port(start_port)
  port = start_port
  port += 1 while is_port_in_use?(port)
  port
end

options = {
  port: 8000,
  directory: Dir.pwd
}

OptionParser.new do |opts|
  opts.banner = "Usage: ruby start_server.rb [options]"

  opts.on("-p", "--port PORT", Integer, "Port to run the server on") do |p|
    options[:port] = p
  end

  opts.on("-d", "--directory DIR", "Directory to serve files from") do |d|
    options[:directory] = d
  end
end.parse!

Dir.chdir(options[:directory])

if is_port_in_use?(options[:port])
  puts "Port #{options[:port]} is already in use."
  options[:port] = find_available_port(options[:port] + 1)
  puts "Trying port #{options[:port]}..."
end

server = WEBrick::HTTPServer.new(
  Port: options[:port],
  DocumentRoot: options[:directory],
  BindAddress: '0.0.0.0'
)

server.mount "/", CustomHTTPServer, options[:directory]

trap('INT') { server.shutdown }

puts "Serving HTTP on 0.0.0.0 port #{options[:port]} (http://0.0.0.0:#{options[:port]}/) ..."
server.start