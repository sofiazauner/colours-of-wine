#!/bin/bash
# Script to read all wine texts and create a summary

# Get base directory from environment variable or use default
BASE="${WINE_DESCRIPTIONS_DIR:-/path/to/wine/descriptions}"

if [ ! -d "$BASE" ]; then
    echo "Error: Directory not found: $BASE" >&2
    echo "Usage: export WINE_DESCRIPTIONS_DIR=\"/path/to/wine/descriptions\"" >&2
    echo "       ./update_all_wines.sh" >&2
    exit 1
fi

echo "Reading all wine descriptions..."
echo ""

# Function to extract URL from text
extract_url() {
    grep -oE 'https?://[^[:space:]]+' "$1" | head -1
}

# Function to extract text without URL
extract_text() {
    grep -vE '^https?://' "$1" | sed '/^$/d' | head -100
}

for wine_dir in "$BASE"/*/; do
    wine_name=$(basename "$wine_dir")
    echo "Processing: $wine_name"
    
    count=0
    for txt_file in "$wine_dir"*.txt "$wine_dir"*.TXT 2>/dev/null; do
        if [ -f "$txt_file" ]; then
            count=$((count + 1))
        fi
    done
    echo "  Found $count description files"
    echo ""
done

