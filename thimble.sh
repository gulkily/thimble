#!/bin/bash

# Global variable to store the path of the started server script
STARTED_SERVER_SCRIPT=""

# Function to find and run a random start_server script
start_server() {
    # Find all start_server.* scripts
    scripts=($(find . -maxdepth 1 -name "start_server.*"))

    if [ ${#scripts[@]} -eq 0 ]; then
        echo "No start_server scripts found."
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
        echo "No compatible start_server scripts found for the current environment."
        return 1
    fi

    # Choose a random script from available ones
    random_script=${available_scripts[$RANDOM % ${#available_scripts[@]}]}

    echo "Running: $random_script"
    STARTED_SERVER_SCRIPT="$random_script"
    case "${random_script##*.}" in
        py)
            python "$random_script"
            ;;
        pl)
            perl "$random_script"
            ;;
        rb)
            ruby "$random_script"
            ;;
        js)
            node "$random_script"
            ;;
        sh)
            bash "$random_script"
            ;;
        php)
            php "$random_script"
            ;;
    esac
}

# Function to stop the server
stop_server() {
    if [ -z "$STARTED_SERVER_SCRIPT" ]; then
        echo "No server is currently running."
        return 1
    fi

    # Construct the stop script name
    stop_script="${STARTED_SERVER_SCRIPT/start_server/stop_server}"

    if [ ! -f "$stop_script" ]; then
        echo "Stop script not found: $stop_script"
        return 1
    fi

    echo "Stopping server with: $stop_script"
    case "${stop_script##*.}" in
        py)
            python "$stop_script"
            ;;
        pl)
            perl "$stop_script"
            ;;
        rb)
            ruby "$stop_script"
            ;;
        js)
            node "$stop_script"
            ;;
        sh)
            bash "$stop_script"
            ;;
        php)
            php "$stop_script"
            ;;
    esac

    STARTED_SERVER_SCRIPT=""
}

# Main function to handle subcommands
t() {
    case "$1" in
        start)
            start_server
            ;;
        stop)
            stop_server
            ;;
        *)
            echo "Usage: t <command>"
            echo "Available commands:"
            echo "  start - Start the server"
            echo "  stop  - Stop the server"
            ;;
    esac
}

# Create the alias
alias t=t

echo "Thimble script loaded. Use 't <command>' to run commands."