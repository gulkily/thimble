#!/bin/bash

# thimble.sh
# to use: source thimble.sh

# Define command-script-description triples
command_scripts=""
command_scripts="$command_scripts start:start_server:Start server @ [port]"
command_scripts="$command_scripts commit:commit_files:Commit messages"
command_scripts="$command_scripts test:test_runner:Run validation tests"
command_scripts="$command_scripts fix:fix_line_endings:Fix line endings"
command_scripts="$command_scripts upgrade:upgrade_from_repo:Check updates"

# Function to find and run a script
run_script() {
	script_name="$1"
	shift  # Remove the first argument (script_name)
	# Find all scripts matching the name
	scripts=$(find template -name "${script_name}.*")

	if [ -z "$scripts" ]; then
		echo "No ${script_name} scripts found."
		return 1
	fi

	# Filter scripts based on available interpreters
	available_scripts=""
	for script in $scripts; do
		case "${script##*.}" in
			py)
				command -v python3 >/dev/null 2>&1 && available_scripts="$available_scripts $script"
				;;
			pl)
				command -v perl >/dev/null 2>&1 && available_scripts="$available_scripts $script"
				;;
			rb)
				command -v ruby >/dev/null 2>&1 && available_scripts="$available_scripts $script"
				;;
			js)
				command -v node >/dev/null 2>&1 && available_scripts="$available_scripts $script"
				;;
			sh)
				available_scripts="$available_scripts $script"
				;;
			php)
				command -v php >/dev/null 2>&1 && available_scripts="$available_scripts $script"
				;;
		esac
	done

	if [ -z "$available_scripts" ]; then
		echo "No compatible ${script_name} scripts found for the current environment."
		return 1
	fi

	# Choose a random script from available ones
	random_script=$(echo $available_scripts | tr ' ' '\n' | sort -R | head -n 1)

	echo "Running: $random_script"
	case "${random_script##*.}" in
		py)
			python3 "$random_script" "$@"
			;;
		pl)
			perl "$random_script" "$@"
			;;
		rb)
			ruby "$random_script" "$@"
			;;
		js)
			node "$random_script" "$@"
			;;
		sh)
			bash "$random_script" "$@"
			;;
		php)
			php "$random_script" "$@"
			;;
	esac
}

# Add test runner function
test_runner() {
	local test_dir="$(pwd)/test-runs/$(date +%Y%m%d-%H%M%S)"
	mkdir -p "$test_dir"
	
	# Clone test repo
	git clone "$(pwd)" "$test_dir/test-repo"
	
	# Run cross-implementation tests
	(cd "$test_dir/test-repo" && \
	 source ../thimble.sh && \
	 python3 template/python3/test_commit_files.py)
	
	echo "Test results available in: $test_dir"
}

# Command definitions with detailed help
command_help() {
	case "$1" in
		start)
			echo "Start the Thimble message server"
			echo "Usage:    t start [port]"
			echo "Default:  port 8080"
			echo "Example:  t start 9090"
			;;
		commit)
			echo "Commit message files with metadata"
			echo "Usage:    t commit [path]"
			echo "Default:  Current directory"
			echo "Example:  t commit ~/my-repo"
			echo "Scans for uncommitted .txt files"
			echo "Creates metadata JSON files"
			echo "Generates Git commits"
			;;
		test)
			echo "Run validation test suite"
			echo "Usage:    t test"
			echo "Verifies:"
			echo "  - Cross-implementation consistency"
			echo "  - Metadata file integrity"
			echo "  - Git history validation"
			;;
		fix)
			echo "Normalize line endings in text files"
			echo "Usage:    t fix [path]"
			echo "Default:  Current directory"
			echo "Converts DOS to UNIX line endings"
			;;
		upgrade)
			echo "Update from upstream repository"
			echo "Usage:    t upgrade"
			echo "Fetches latest version from GitHub"
			echo "Preserves local messages and config"
			;;
		*)
			echo "No detailed help for: $1"
			;;
	esac
}

# Improved help display
show_help() {
	echo "Usage: t <command> [arguments...]"
	echo "Available commands:"
	echo "$command_scripts" | tr ' ' '\n' | while IFS=: read -r cmd script desc; do
		printf "  %-12s %s\n" "$cmd" "$desc"
	done
	echo "\nUse 't help <command>' for detailed command help"
}

# Main function with improved help handling
t() {
	if [ -z "$1" ]; then
		show_help
		return
	fi

	case "$1" in
		help|--help|-h)
			if [ -n "$2" ]; then
				# Show detailed command help
				selected_cmd="$2"
				found=$(echo "$command_scripts" | tr ' ' '\n' | grep "^$selected_cmd:")
				if [ -n "$found" ]; then
					IFS=: read -r cmd script desc <<< "$found"
					echo "Command: $cmd"
					echo "Description: $desc"
					echo "Usage: t $cmd [options]"
					command_help "$cmd"
				else
					echo "No help available for unknown command: $selected_cmd"
				fi
			else
				show_help
			fi
			return
			;;
	esac

	script_name=$(echo "$command_scripts" | tr ' ' '\n' | grep "^$1:" | cut -d':' -f2)
	if [ -n "$script_name" ]; then
		shift  # Remove the first argument (command name)
		run_script "$script_name" "$@"
	else
		echo "Unknown command: $1"
		echo "Use 't' without arguments to see available commands."
	fi
}

# Create the alias
alias t=t

echo "Thimble script loaded. Use 't <command> [arguments...]' to run commands."

# end of thimble.sh
