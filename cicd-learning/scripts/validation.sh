#!/usr/bin/env bash

if [[ $# -ne 1 || -z "$1" ]]; then
    echo "Error: exactly one non-empty name is required." >&2
    echo "Usage: $0 <name>" >&2
    exit 1
fi

name="$1"

echo "Hello, ${name}!"
echo "Hello, ${name}! Welcome to GitHub."
