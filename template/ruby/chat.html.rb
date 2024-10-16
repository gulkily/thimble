# chat.html.rb
# to run: ruby chat.html.rb

# DOES NOT WORK YET #todo

require 'date'
require 'fileutils'
require 'optparse'
require 'parallel'

DEBUG = false

def debug_print(*args)
  puts(*args) if DEBUG
end

def read_file(file_path)
  File.read(file_path)
end

AUTHOR_REGEX = /Author:\s*(.+)/i
HASHTAG_REGEX = /#\w+/

def extract_metadata(content)
  author = content.match(AUTHOR_REGEX)
  author = author ? author[1] : "Unknown"
  hashtags = content.scan(HASHTAG_REGEX)
  [author, hashtags]
end

def truncate_message(content, max_length = 300)
  if content.length <= max_length
    [content, false]
  else
    [content[0...max_length] + "...", true]
  end
end

def relative_path(path, start)
  path = File.expand_path(path)
  start = File.expand_path(start)
  path.sub(/^#{Regexp.escape(start)}\//, '')
end

def process_file(file_path, repo_path)
  rel_path = relative_path(file_path, repo_path)
  begin
    creation_time = File.ctime(file_path)
    content = File.read(file_path, encoding: 'UTF-8')
    author, hashtags = extract_metadata(content)
    content = content.gsub(/author:\s*.+/i, '').strip
    {
      author: author,
      content: content,
      timestamp: creation_time,
      hashtags: hashtags
    }
  rescue => e
    debug_print("Error reading file #{file_path}: #{e.message}")
    nil
  end
end

def generate_chat_html(repo_path, output_file, max_messages = 50, max_message_length = 300, title = "THIMBLE Chat")
  html_template = read_file('./template/html/chat_page.html')
  message_template = read_file('./template/html/chat_message.html')
  css_style = read_file('./template/css/chat_style.css')
  js_template = read_file('./template/js/chat.js')

  message_dir = File.join(repo_path, "message")

  file_paths = Dir.glob(File.join(message_dir, "**", "*.txt"))

  messages = Parallel.map(file_paths) { |file_path| process_file(file_path, repo_path) }

  messages.compact!
  messages.sort_by! { |msg| msg[:timestamp] }.reverse!
  messages = messages.take(max_messages)

  chat_messages = messages.map.with_index do |msg, idx|
    truncated_content, is_truncated = truncate_message(msg[:content], max_message_length)
    expand_link = is_truncated ? "<a href=\"#\" class=\"expand-link\" data-message-id=\"#{idx}\">Show More</a>" : ""
    full_content = is_truncated ? "<div class=\"full-message\" id=\"full-message-#{idx}\" style=\"display: none;\">#{msg[:content]}</div>" : ""

    message_template % {
      author: msg[:author],
      content: truncated_content,
      full_content: full_content,
      expand_link: expand_link,
      timestamp: msg[:timestamp].strftime('%Y-%m-%d %H:%M:%S'),
      hashtags: msg[:hashtags].join(' ')
    }
  end

  html_content = html_template % {
    style: css_style,
    chat_messages: chat_messages.join,
    message_count: messages.length,
    current_time: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
    title: title
  }

  html_content.sub!('</body>', "<script>#{js_template}</script></body>")

  File.write(output_file, html_content)
end

if __FILE__ == $0
  options = {
    repo_path: ".",
    output_file: "chat.html",
    max_messages: 50,
    max_message_length: 300,
    title: "THIMBLE Chat",
    debug: false
  }

  OptionParser.new do |opts|
    opts.banner = "Usage: ruby chat.html.rb [options]"

    opts.on("--repo_path PATH", "Path to the repository") { |v| options[:repo_path] = v }
    opts.on("--output_file FILE", "Output HTML file name") { |v| options[:output_file] = v }
    opts.on("--max_messages NUM", Integer, "Maximum number of messages to display") { |v| options[:max_messages] = v }
    opts.on("--max_message_length NUM", Integer, "Maximum length of each message before truncation") { |v| options[:max_message_length] = v }
    opts.on("--title TITLE", "Title of the chat page") { |v| options[:title] = v }
    opts.on("--debug", "Enable debug output") { |v| options[:debug] = v }
  end.parse!

  DEBUG = options[:debug]

  generate_chat_html(options[:repo_path], options[:output_file], options[:max_messages], options[:max_message_length], options[:title])
  debug_print("Chat log generated: #{options[:output_file]}")
  debug_print("Script completed.")
end
