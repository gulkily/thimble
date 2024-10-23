#!/usr/bin/tclsh

# start_server.tcl
# to run: tclsh start_server.tcl

# start_server: v3

package require http

# Global variables
set port 8000
set directory [pwd]

# Function to check if a port is in use
proc is_port_in_use {port} {
    if {[catch {socket -server dummy $port} sock]} {
        return 1
    } else {
        close $sock
        return 0
    }
}

# Function to find an available port
proc find_available_port {start_port} {
    set port $start_port
    while {[is_port_in_use $port]} {
        incr port
    }
    return $port
}

# Function to handle HTTP requests
proc handle_request {chan clientaddr clientport} {
    set request [gets $chan]
    set method [lindex $request 0]
    set path [lindex $request 1]

    if {$method eq "GET"} {
        if {$path eq "/"} {
            serve_file $chan "index.html"
        } elseif {$path eq "/log.html"} {
            check_and_generate_report
            serve_file $chan "log.html"
        } elseif {$path eq "/chat.html"} {
            check_and_generate_chat_html
            serve_file $chan "chat.html"
        } elseif {$path eq "/api/github_update"} {
            handle_github_update $chan
        } elseif {[string match "*.txt" $path]} {
            serve_text_file $chan $path
        } else {
            serve_file $chan [string trimleft $path "/"]
        }
    } elseif {$method eq "POST" && $path eq "/chat.html"} {
        handle_chat_post $chan
    } else {
        send_error $chan 405 "Method Not Allowed"
    }

    close $chan
}

# Function to check and generate report
proc check_and_generate_report {} {
    global directory
    set html_file [file join $directory "log.html"]
    if {![file exists $html_file] || [expr {[clock seconds] - [file mtime $html_file]} > 60]} {
        puts "$html_file is older than 60 seconds or does not exist. Running log.html.py..."
        exec python log.html.py
    } else {
        puts "$html_file is up-to-date."
    }
}

# Function to check and generate chat HTML
proc check_and_generate_chat_html {} {
    global directory
    set chat_html_file [file join $directory "chat.html"]
    if {![file exists $chat_html_file] || [expr {[clock seconds] - [file mtime $chat_html_file]} > 60]} {
        puts "$chat_html_file is older than 60 seconds or does not exist. Running chat.html.py..."
        run_script "chat.html"
    } else {
        puts "$chat_html_file is up-to-date."
    }
}

# Function to handle GitHub update
proc handle_github_update {chan} {
    puts $chan "HTTP/1.1 200 OK"
    puts $chan "Content-Type: text/html"
    puts $chan ""
    puts $chan "Update triggered successfully"
    exec python github_update.py
}

# Function to handle chat post
proc handle_chat_post {chan} {
    set content [read $chan]
    set params [split $content &]
    array set form_data {}
    foreach param $params {
        set pair [split $param =]
        set form_data([lindex $pair 0]) [http::decode [lindex $pair 1]]
    }

    if {[info exists form_data(author)] && [info exists form_data(message)]} {
        save_message $form_data(author) $form_data(message)
        puts $chan "HTTP/1.1 200 OK"
        puts $chan "Content-Type: text/html"
        puts $chan ""
        puts $chan "Message saved successfully<meta http-equiv=\"refresh\" content=\"1;url=chat.html\">"
        exec python commit_files.py message
        exec python github_update.py
    } else {
        send_error $chan 400 "Bad Request: Missing author or message"
    }
}

# Function to save message
proc save_message {author message} {
    global directory
    set today [clock format [clock seconds] -format "%Y-%m-%d"]
    set dir [file join $directory "message" $today]
    file mkdir $dir

    set title [generate_title $message]
    set filename "$title.txt"
    set filepath [file join $dir $filename]

    set fh [open $filepath w]
    puts $fh "$message\n\nauthor: $author"
    close $fh
}

# Function to generate title
proc generate_title {message} {
    set words [split $message]
    set title [join [lrange $words 0 4] "_"]
    regsub -all {[^a-zA-Z0-9_-]} $title "" title
    if {$title eq ""} {
        set title [string range [expr rand()] 2 11]
    }
    return $title
}

# Function to serve file
proc serve_file {chan path} {
    global directory
    set file [file join $directory $path]

    if {[file exists $file]} {
        set fh [open $file r]
        set content [read $fh]
        close $fh

        set content_type [get_content_type $file]
        puts $chan "HTTP/1.1 200 OK"
        puts $chan "Content-Type: $content_type"
        puts $chan ""
        puts $chan $content
    } else {
        send_error $chan 404 "Not Found"
    }
}

# Function to serve text file
proc serve_text_file {chan path} {
    global directory
    set file [file join $directory [string trimleft $path "/"]]

    if {[file exists $file]} {
        set fh [open $file r]
        set content [read $fh]
        close $fh

        set html_content [generate_html_for_text_file [file tail $file] $content]
        puts $chan "HTTP/1.1 200 OK"
        puts $chan "Content-Type: text/html; charset=utf-8"
        puts $chan ""
        puts $chan $html_content
    } else {
        send_error $chan 404 "Not Found"
    }
}

# Function to generate HTML for text file
proc generate_html_for_text_file {filename content} {
    set content [string map {& &amp; < &lt; > &gt;} $content]
    return "<!DOCTYPE html>
<html lang=\"en\">
<head>
    <meta charset=\"UTF-8\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
    <title>$filename</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; padding: 20px; }
        pre { background-color: #f4f4f4; padding: 15px; border-radius: 5px; white-space: pre-wrap; word-wrap: break-word; }
    </style>
</head>
<body>
    <h1>$filename</h1>
    <pre>$content</pre>
</body>
</html>"
}

# Function to get content type
proc get_content_type {file} {
    array set mime_types {
        .txt "text/plain"
        .html "text/html"
        .css "text/css"
        .js "application/javascript"
        .json "application/json"
        .png "image/png"
        .jpg "image/jpeg"
        .gif "image/gif"
    }
    set ext [string tolower [file extension $file]]
    if {[info exists mime_types($ext)]} {
        return $mime_types($ext)
    } else {
        return "application/octet-stream"
    }
}

# Function to send error
proc send_error {chan code message} {
    puts $chan "HTTP/1.1 $code $message"
    puts $chan "Content-Type: text/plain"
    puts $chan ""
    puts $chan "$code $message"
}

# Function to run script
proc run_script {script_name} {
    set script_types {py pl rb sh js}
    set interpreters {python3 perl ruby bash node}
    array set interpreter_map {}
    foreach type $script_types interpreter $interpreters {
        set interpreter_map($type) $interpreter
    }

    set found_scripts {}

    foreach dir [glob -nocomplain -type d template/*] {
        foreach type $script_types {
            set full_path [file join $dir "$script_name.$type"]
            if {[file exists $full_path]} {
                lappend found_scripts $full_path
            }
        }
    }

    if {[llength $found_scripts] == 0} {
        puts "No scripts found for $script_name"
        return
    }

    foreach script $found_scripts {
        set type [file extension $script]
        set type [string trimleft $type .]
        if {[info exists interpreter_map($type)]} {
            set interpreter $interpreter_map($type)
            puts "Running $script with $interpreter..."
            exec $interpreter $script
        } else {
            puts "No suitable interpreter found for $script"
        }
    }
}

# Main execution
if {[is_port_in_use $port]} {
    puts "Port $port is already in use."
    set port [find_available_port [expr {$port + 1}]]
    puts "Trying port $port..."
}

puts "Serving HTTP on 0.0.0.0 port $port (http://0.0.0.0:$port/) ..."
socket -server handle_request $port
vwait forever

# end of start_server.tcl