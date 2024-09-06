#!/bin/bash

# Function to read a file
read_file() {
  cat "$1"
}

# Function to extract metadata
extract_metadata() {
  local content="$1"
  author=$(echo "$content" | grep -i 'Author:' | sed 's/Author:\s*//I')
  hashtags=$(echo "$content" | grep -o '#\w+' | tr '\n' ', ' | sed 's/, $//')
}

# Function to escape special characters for sed
escape_for_sed() {
  echo "$1" | sed -e 's/[\/&]/\\&/g'
}

# Function to generate HTML
generate_html() {
  local repo_path="$1"
  local output_file="$2"

  HTML_TEMPLATE=$(read_file "./template/html/page.html")
  TABLE_ROW_TEMPLATE=$(read_file "./template/html/page_row.html")
  CSS_STYLE=$(read_file "./template/css/webmail.css")

  table_rows=""
  file_count=0

  while IFS= read -r -d '' file_path; do
    relative_path=$(realpath --relative-to="$repo_path" "$file_path")

    commit_timestamp=$(git log -1 --format="%ci" -- "$relative_path")
    commit_timestamp=${commit_timestamp:-"N/A"}

    stored_date=$(basename "$(dirname "$file_path")")

    content=$(cat "$file_path")
    extract_metadata "$content"

    row=$(printf "%s" "$TABLE_ROW_TEMPLATE" | sed -e "s|{relative_path}|$(escape_for_sed "$relative_path")|" \
                                                  -e "s|{commit_timestamp}|$(escape_for_sed "$commit_timestamp")|" \
                                                  -e "s|{stored_date}|$(escape_for_sed "$stored_date")|" \
                                                  -e "s|{author}|$(escape_for_sed "$author")|" \
                                                  -e "s|{hashtags}|$(escape_for_sed "$hashtags")|")

    table_rows="${table_rows}${row}"

    file_count=$((file_count + 1))
    if [ "$file_count" -ge 100 ]; then
      break
    fi
  done < <(find "$repo_path/message" -type f -name "*.txt" -print0)

  html_content=$(printf "%s" "$HTML_TEMPLATE" | sed -e "s|{style}|$(escape_for_sed "$CSS_STYLE")|" \
                                                    -e "s|{table_rows}|$(escape_for_sed "$table_rows")|" \
                                                    -e "s|{file_count}|$file_count|" \
                                                    -e "s|{current_time}|$(date +'%Y-%m-%d %H:%M:%S')|" \
                                                    -e "s|{title}|THIMBLE|")

  echo "$html_content" > "$output_file"
}

# Main function
main() {
  repo_path="."  # Current directory
  output_file="log.html"
  generate_html "$repo_path" "$output_file"
  echo "Report generated: $output_file"
}

main
