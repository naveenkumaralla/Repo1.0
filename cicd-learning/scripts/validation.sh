#!/usr/bin/env bash

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <name>"
    exit 1
fi

echo "Hello, $1"
