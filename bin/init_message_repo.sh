#!/bin/sh

if [ ! -d "message" ]; then
    git init message
    pushd message
        git config user.email "you@example.com"
        git config user.name "Your Name"
    popd
fi
