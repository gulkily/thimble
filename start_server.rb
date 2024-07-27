# start_server.rb
# to run: ruby start_server.rb

require 'webrick'
require 'optparse'
require 'time'
require 'cgi'

class CustomHTTPHandler < WEBrick::HTTPServlet::FileHandler
  def initialize(server, root)
    super
    @root = root
  end

  def do_GET(req, res)
    if req.path == '/'
      check_and_generate_report
      super
    elsif req.path.end_with?('.txt')
      serve_text_file(req, res)
    else
      super
    end
  end

  def check_and_generate_report
    html_file = File.join(@root, 'index.html')
    if !File.exist?(html_file) || Time.now - File.mtime(html_file) > 60
      puts "#{html_file} is older than 60 seconds or does not exist. Running generate_report.rb..."
      system('ruby generate_report.rb')
    else
      puts "#{html_file} is up-to-date."
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

def run_server(port, directory)
  Dir.chdir(directory)
  server = WEBrick::HTTPServer.new(Port: port, DocumentRoot: directory)
  server.mount('/', CustomHTTPHandler, directory)

  trap('INT') { server.shutdown }
  puts "Serving HTTP on 0.0.0.0 port #{port} (http://0.0.0.0:#{port}/) ..."
  server.start
end

if __FILE__ == $PROGRAM_NAME
  options = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: ruby script.rb [options]"
    opts.on("-p", "--port PORT", Integer, "Port to serve on (default: 8000)") { |p| options[:port] = p }
    opts.on("-d", "--directory DIR", String, "Directory to serve (default: current directory)") { |d| options[:directory] = d }
  end.parse!

  port = options[:port] || 8000
  directory = options[:directory] || Dir.pwd

  run_server(port, directory)
end
