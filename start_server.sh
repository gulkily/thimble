#!/bin/bash

# start_server.sh
# to run: ./start_server.sh

PORT=8000
DIRECTORY=$(pwd)

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -p|--port)
        PORT="$2"
        shift
        shift
        ;;
        -d|--directory)
        DIRECTORY="$2"
        shift
        shift
        ;;
        *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
done

# Change to the specified directory
cd "$DIRECTORY" || exit

# Function to generate HTTP headers
generate_headers() {
    local status="$1"
    local content_type="$2"
    echo -e "HTTP/1.1 $status\r\nContent-Type: $content_type\r\n\r\n"
}

# Function to serve a file
serve_file() {
    local file="$1"
    local content_type

    case "${file##*.}" in
        html) content_type="text/html" ;;
        js)   content_type="text/javascript" ;;
        css)  content_type="text/css" ;;
        json) content_type="application/json" ;;
        png)  content_type="image/png" ;;
        jpg|jpeg) content_type="image/jpeg" ;;
        gif)  content_type="image/gif" ;;
        *)    content_type="application/octet-stream" ;;
    esac

    if [[ -f "$file" ]]; then
        generate_headers "200 OK" "$content_type"
        cat "$file"
    else
        generate_headers "404 Not Found" "text/plain"
        echo "404 Not Found"
    fi
}

# Function to serve a text file with HTML wrapper
serve_text_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        generate_headers "200 OK" "text/html; charset=utf-8"
        echo "<!DOCTYPE html>"
        echo "<html lang=\"en\">"
        echo "<head>"
        echo "    <meta charset=\"UTF-8\">"
        echo "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"
        echo "    <title>$(basename "$file")</title>"
        echo "    <style>"
        echo "        body { font-family: Arial, sans-serif; line-height: 1.6; padding: 20px; }"
        echo "        pre { background-color: #f4f4f4; padding: 15px; border-radius: 5px; white-space: pre-wrap; word-wrap: break-word; }"
        echo "    </style>"
        echo "</head>"
        echo "<body>"
        echo "    <h1>$(basename "$file")</h1>"
        echo "    <pre>"
        sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g' "$file"
        echo "    </pre>"
        echo "</body>"
        echo "</html>"
    else
        generate_headers "404 Not Found" "text/plain"
        echo "404 Not Found"
    fi
}

# Function to check and generate report
check_and_generate_report() {
    local html_file="index.html"
    if [[ ! -f "$html_file" ]] || [[ $(( $(date +%s) - $(date -r "$html_file" +%s) )) -gt 60 ]]; then
        echo "$html_file is older than 60 seconds or does not exist. Running generate_report.js..."
        node generate_report.js
    else
        echo "$html_file is up-to-date."
    fi
}

# Function to handle a single request
handle_request() {
    local request
    read -r request

    if [[ -n "$request" ]]; then
        local path
        path=$(echo "$request" | awk '{print $2}')

        if [[ "$path" == "/" ]]; then
            check_and_generate_report
            serve_file "index.html"
        elif [[ "$path" == *.txt ]]; then
            serve_text_file "${path#/}"
        else
            serve_file "${path#/}"
        fi
    fi
}

# Main server loop
echo "Serving HTTP on 0.0.0.0 port $PORT (http://0.0.0.0:$PORT/) ..."
while true; do
    # Use coproc to run netcat in the background
    coproc nc -l -p "$PORT"
    
    # Handle the request
    handle_request <&"${COPROC[0]}" >&"${COPROC[1]}"
    
    # Close the file descriptors
    exec {COPROC[0]}<&- {COPROC[1]}>&-
done
