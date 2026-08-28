#!/usr/bin/env bash

if [[ $# -ne 1 || -z "$1" ]]; then
    echo "Error: exactly one non-empty name is required." >&2
    echo "Usage: $0 <name>" >&2
    exit 1
fi

name="$1"

echo "BROKEN OUTPUT"
echo "Hello, ${name}!"
echo "Welcome to the CI/CD lab!"
