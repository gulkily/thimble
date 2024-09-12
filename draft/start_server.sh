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

serve_file() {
	local file="$1"
	local content_type="text/plain"

	case "${file##*.}" in
	html) content_type="text/html" ;;
	js)   content_type="text/javascript" ;;
	css)  content_type="text/css" ;;
	json) content_type="application/json" ;;
	png)  content_type="image/png" ;;
	jpg|jpeg) content_type="image/jpeg" ;;
	gif)  content_type="image/gif" ;;
	esac

	if [[ -f "$file" ]]; then
	local content_length=$(wc -c < "$file")
	echo -e "HTTP/1.1 200 OK\r\nContent-Type: $content_type\r\nContent-Length: $content_length\r\nConnection: close\r\n\r\n"
	cat "$file"
	else
	echo -e "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\nContent-Length: 13\r\nConnection: close\r\n\r\n404 Not Found"
	fi
}

handle_request() {
	read -r request_line
	echo "Received: $request_line" >&2

	# Read and discard headers
	while read -r header; do
	header=${header%$'\r'}
	[ -z "$header" ] && break
	echo "Header: $header" >&2
	done

	request_path=$(echo "$request_line" | awk '{print $2}')
	echo "Requested path: $request_path" >&2

	if [[ "$request_path" == "/" ]]; then
	serve_file "index.html"
	else
	serve_file "${request_path#/}"
	fi
}

echo "Serving HTTP on 0.0.0.0 port $PORT (http://localhost:$PORT/) ..."
while true; do
	{ echo -ne "HTTP/1.1 100 Continue\r\n\r\n"; handle_request; } | nc -l -p "$PORT"
done