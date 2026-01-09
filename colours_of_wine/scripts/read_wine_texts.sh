#!/bin/bash
# Script to read all wine description texts and output them

# Get base directory from environment variable or use default
BASE_DIR="${WINE_DESCRIPTIONS_DIR:-/path/to/wine/descriptions}"

if [ ! -d "$BASE_DIR" ]; then
    echo "Error: Directory not found: $BASE_DIR" >&2
    echo "Usage: export WINE_DESCRIPTIONS_DIR=\"/path/to/wine/descriptions\"" >&2
    echo "       ./read_wine_texts.sh" >&2
    exit 1
fi

for wine_dir in "$BASE_DIR"/*/; do
    wine_name=$(basename "$wine_dir")
    echo "=== $wine_name ==="
    
    for txt_file in "$wine_dir"*.txt "$wine_dir"*.TXT; do
        if [ -f "$txt_file" ]; then
            filename=$(basename "$txt_file")
            echo "--- $filename ---"
            cat "$txt_file"
            echo ""
        fi
    done
    echo ""
done

