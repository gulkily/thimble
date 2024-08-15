#!/bin/sh

function main() {
    local repo_dir="${1:-message}"

    if [ ! -d "${repo_dir}" ]; then
        git init "${repo_dir}"
        pushd "${repo_dir}"
            git config user.email "you@example.com"
            git config user.name "Your Name"
        popd
    fi
}

main "$@"
