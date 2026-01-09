#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script to extract all wine description texts from TXT files and generate Dart code

Usage:
    Set WINE_DESCRIPTIONS_DIR environment variable or pass as argument:
    export WINE_DESCRIPTIONS_DIR="/path/to/wine/descriptions"
    python3 extract_all_wines.py

    Or:
    python3 extract_all_wines.py "/path/to/wine/descriptions"
"""
import os
import re
import sys
from pathlib import Path

def extract_url(text):
    """Extract first URL from text"""
    urls = re.findall(r'https?://[^\s]+', text)
    return urls[0] if urls else None

def clean_text(text, url):
    """Remove URL from text and clean up"""
    if url:
        text = text.replace(url, '').strip()
    # Remove multiple empty lines
    text = re.sub(r'\n\s*\n\s*\n+', '\n\n', text)
    return text.strip()

def escape_dart_string(text):
    """Escape string for Dart"""
    # Replace newlines with \n and escape quotes
    text = text.replace('\\', '\\\\')
    text = text.replace('$', r'\$')
    text = text.replace('"', '\\"')
    # Keep newlines as \n
    text = text.replace('\n', '\\n')
    return text

def read_wine_descriptions(base_dir_path):
    """Read wine descriptions from directory"""
    base_dir = Path(base_dir_path)
    if not base_dir.exists():
        print(f"Error: Directory not found: {base_dir}")
        return {}
    
    wines_data = {}
    
    # Map folder names to wine IDs
    wine_mapping = {
        "01 Chardonnay Markowitsch": "1",
        "02 Tignanello": "2",
        "03 Riesling Bürklin": "3",
        "04 Ducru Beaucaillou": "4",
        "07 Welschriesling TBA Kracher": "5",
        "08 Pinot Noir Südfrankreich": "6",
        "09 Zweigelt Achs": "7",
        "10 Brut rosé Reserve Loimer": "8",
        "04 Sauvignon blanc Cloudy Bay": "9",
        "05 Weissburgunder Gross": "10",
    }
    
    for wine_dir in sorted(base_dir.iterdir()):
        if not wine_dir.is_dir():
            continue
        
        wine_name = wine_dir.name
        wine_id = wine_mapping.get(wine_name)
        
        if not wine_id:
            # Try to find partial match
            for key, value in wine_mapping.items():
                if key in wine_name or wine_name in key:
                    wine_id = value
                    break
        
        if not wine_id:
            print(f"Warning: No mapping found for {wine_name}")
            continue
        
        descriptions = []
        
        for txt_file in sorted(wine_dir.glob("*.txt")) + sorted(wine_dir.glob("*.TXT")):
            try:
                with open(txt_file, 'r', encoding='utf-8') as f:
                    content = f.read()
            except UnicodeDecodeError:
                try:
                    with open(txt_file, 'r', encoding='latin-1') as f:
                        content = f.read()
                except Exception as e:
                    print(f"Error reading {txt_file}: {e}")
                    continue
            except Exception as e:
                print(f"Error reading {txt_file}: {e}")
                continue
            
            source_name = txt_file.stem
            url = extract_url(content)
            text = clean_text(content, url)
            
            if text:  # Only add if text was extracted
                descriptions.append({
                    "source": source_name,
                    "text": text,
                    "url": url,
                })
        
        if descriptions:
            wines_data[wine_id] = {
                "name": wine_name,
                "descriptions": descriptions
            }
    
    return wines_data

def generate_dart_code(wines_data):
    """Generate Dart code for wine descriptions"""
    output = []
    
    for wine_id in sorted(wines_data.keys(), key=int):
        wine = wines_data[wine_id]
        output.append(f"    // Wine ID {wine_id}: {wine['name']}")
        output.append("    descriptions: [")
        
        for i, desc in enumerate(wine['descriptions'], 1):
            source = desc['source']
            text_escaped = escape_dart_string(desc['text'])
            url_param = f'\n        url: \'{desc["url"]}\',' if desc['url'] else ''
            
            output.append(f"      WineDescription(")
            output.append(f"        id: '{wine_id}-{i}',")
            output.append(f"        source: '{source}',{url_param}")
            output.append(f"        text: '{text_escaped}',")
            output.append(f"      ),")
        
        output.append("    ],")
        output.append("")
    
    return "\n".join(output)

if __name__ == "__main__":
    # Get base directory from environment variable or command line argument
    base_dir = os.environ.get('WINE_DESCRIPTIONS_DIR')
    
    if len(sys.argv) > 1:
        base_dir = sys.argv[1]
    
    if not base_dir:
        print("Error: No wine descriptions directory specified")
        print("Usage:")
        print("  export WINE_DESCRIPTIONS_DIR=\"/path/to/wine/descriptions\"")
        print("  python3 extract_all_wines.py")
        print("")
        print("  Or:")
        print("  python3 extract_all_wines.py \"/path/to/wine/descriptions\"")
        sys.exit(1)
    
    try:
        wines_data = read_wine_descriptions(base_dir)
        
        if not wines_data:
            print("No wine data found")
        else:
            # Output as JSON-like structure for manual integration
            print("=" * 80)
            print("WINE DESCRIPTIONS DATA")
            print("=" * 80)
            print()
            
            for wine_id in sorted(wines_data.keys(), key=int):
                wine = wines_data[wine_id]
                print(f"Wine ID {wine_id}: {wine['name']}")
                print(f"  {len(wine['descriptions'])} descriptions found")
                for desc in wine['descriptions']:
                    print(f"    - {desc['source']}: {len(desc['text'])} chars")
                print()
            
            # Save to file for reference
            script_dir = Path(__file__).parent
            output_file = script_dir / 'wine_descriptions_output.txt'
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(generate_dart_code(wines_data))
            
            print(f"Dart code saved to {output_file}")
            print(f"Total wines processed: {len(wines_data)}")
            
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

