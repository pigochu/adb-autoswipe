#!/bin/bash

# Load configurations from .env
load_config() {
    if [ ! -f .env ]; then
        echo "Error: .env file not found."
        return 1
    fi
    source .env
    
    # Set defaults if not provided
    INTERVAL=${INTERVAL:-5}
    return 0
}

# Main entry for config check
if [ "$1" == "--check-config" ]; then
    load_config
    exit $?
fi
