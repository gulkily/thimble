#!/bin/bash

# thimble.sh
# to use: source thimble.sh

# Define command-script pairs
declare -A command_scripts
command_scripts=(
	["start"]="start_server"
	["upgrade"]="upgrade_from_repo"
	["fix"]="fix_line_endings"
	["commit"]="commit_files"
	# Add new commands here in the format:
	# ["command_name"]="script_name"
)

# Function to find and run a script
run_script() {
	script_name="$1"
	shift  # Remove the first argument (script_name)
	# Find all scripts matching the name
	readarray -t scripts < <(find template -name "${script_name}.*")

	if [ ${#scripts[@]} -eq 0 ]; then
		echo "No ${script_name} scripts found."
		return 1
	fi

	# Filter scripts based on available interpreters
	available_scripts=()
	for script in "${scripts[@]}"; do
		case "${script##*.}" in
			py)
				command -v python >/dev/null 2>&1 && available_scripts+=("$script")
				;;
			pl)
				command -v perl >/dev/null 2>&1 && available_scripts+=("$script")
				;;
			rb)
				command -v ruby >/dev/null 2>&1 && available_scripts+=("$script")
				;;
			js)
				command -v node >/dev/null 2>&1 && available_scripts+=("$script")
				;;
			sh)
				available_scripts+=("$script")
				;;
			php)
				command -v php >/dev/null 2>&1 && available_scripts+=("$script")
				;;
		esac
	done

	if [ ${#available_scripts[@]} -eq 0 ]; then
		echo "No compatible ${script_name} scripts found for the current environment."
		return 1
	fi

	# Choose a random script from available ones
	random_script=${available_scripts[$RANDOM % ${#available_scripts[@]}]}

	echo "Running: $random_script"
	case "${random_script##*.}" in
		py)
			python "$random_script" "$@"
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

# Main function to handle subcommands
t() {
	if [ -z "$1" ]; then
		echo "Usage: t <command> [arguments...]"
		echo "Available commands:"
		for cmd in "${!command_scripts[@]}"; do
			echo "  $cmd"
		done
		return
	fi

	script_name="${command_scripts[$1]}"
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
