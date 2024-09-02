#!/bin/bash

# test_log.html.sh
# to run: bash test_log.html.sh

run_generate_report() {
    start_time=$(date +%s.%N)
    output=$($1 2>&1)
    return_code=$?
    end_time=$(date +%s.%N)
    execution_time=$(echo "$end_time - $start_time" | bc)
    echo "$return_code:$output:$execution_time"
}

check_output_file() {
    [ -f "$1" ] && [ -s "$1" ]
}

scripts=(
    "python3 log.html.py"
    "php log.html.php"
    "node log.html.js"
    "bash log.html.sh"
)

for script in "${scripts[@]}"; do
    echo -e "\nTesting: $script"

    # Run the script
    IFS=':' read -r return_code output execution_time <<< $(run_generate_report "$script")

    # Check return code
    if [ $return_code -ne 0 ]; then
        echo "Script failed with return code $return_code"
        exit 1
    fi
    echo "Script executed successfully"

    # Check execution time
    if (( $(echo "$execution_time > 60" | bc -l) )); then
        echo "Script took too long to execute: ${execution_time} seconds"
        exit 1
    fi
    echo "Execution time: ${execution_time} seconds"

    # Check if output file exists and is not empty
    if ! check_output_file "log.html"; then
        echo "Output file 'log.html' is missing or empty"
        exit 1
    fi
    echo "Output file 'log.html' generated successfully"

    # Clean up
    rm -f log.html
done

echo -e "\nAll tests passed successfully!"

# end of test_log.html.sh