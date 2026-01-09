#!/usr/bin/env python3
"""
Script to extract text from TXT files in the wine descriptions folder

Usage:
    export WINE_DESCRIPTIONS_DIR="/path/to/wine/descriptions"
    python3 extract_txt_texts.py
"""
import os
import json
import sys
from pathlib import Path

def extract_text_from_txt(txt_path):
    """Extract text from TXT file"""
    try:
        with open(txt_path, 'r', encoding='utf-8') as file:
            return file.read().strip()
    except UnicodeDecodeError:
        # Try with different encoding
        try:
            with open(txt_path, 'r', encoding='latin-1') as file:
                return file.read().strip()
        except Exception as e:
            print(f"Error reading {txt_path}: {e}", file=sys.stderr)
            return ""
    except Exception as e:
        print(f"Error reading {txt_path}: {e}", file=sys.stderr)
        return ""

def main():
    # Get base directory from environment variable or command line argument
    base_dir_path = os.environ.get('WINE_DESCRIPTIONS_DIR')
    
    if len(sys.argv) > 1:
        base_dir_path = sys.argv[1]
    
    if not base_dir_path:
        print("Error: No wine descriptions directory specified", file=sys.stderr)
        print("Usage: export WINE_DESCRIPTIONS_DIR=\"/path/to/wine/descriptions\"", file=sys.stderr)
        print("       python3 extract_txt_texts.py", file=sys.stderr)
        return
    
    base_dir = Path(base_dir_path)
    if not base_dir.exists():
        print(f"Directory not found: {base_dir}")
        return
    
    wines_data = {}
    
    for wine_dir in sorted(base_dir.iterdir()):
        if not wine_dir.is_dir():
            continue
        
        wine_name = wine_dir.name
        descriptions = []
        
        # Look for both .txt and .TXT files
        for txt_file in sorted(wine_dir.glob("*.txt")) + sorted(wine_dir.glob("*.TXT")):
            source_name = txt_file.stem  # Filename without extension
            text = extract_text_from_txt(txt_file)
            
            if text:  # Only add if text was extracted
                descriptions.append({
                    "source": source_name,
                    "text": text,
                    "url": None
                })
        
        if descriptions:
            wines_data[wine_name] = descriptions
    
    # Output as JSON
    print(json.dumps(wines_data, indent=2, ensure_ascii=False))

if __name__ == "__main__":
    main()

