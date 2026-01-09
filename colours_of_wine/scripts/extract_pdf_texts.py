#!/usr/bin/env python3
"""
Script to extract text from PDF files in the wine descriptions folder

Usage:
    export WINE_DESCRIPTIONS_DIR="/path/to/wine/descriptions"
    python3 extract_pdf_texts.py
"""
import os
import json
import sys
from pathlib import Path

try:
    import PyPDF2
    HAS_PYPDF2 = True
except ImportError:
    HAS_PYPDF2 = False

try:
    import pdfplumber
    HAS_PDFPLUMBER = True
except ImportError:
    HAS_PDFPLUMBER = False

def extract_text_pypdf2(pdf_path):
    """Extract text using PyPDF2"""
    try:
        with open(pdf_path, 'rb') as file:
            reader = PyPDF2.PdfReader(file)
            text = ""
            for page in reader.pages:
                text += page.extract_text() + "\n"
            return text.strip()
    except Exception as e:
        print(f"Error reading {pdf_path}: {e}", file=sys.stderr)
        return ""

def extract_text_pdfplumber(pdf_path):
    """Extract text using pdfplumber"""
    try:
        with pdfplumber.open(pdf_path) as pdf:
            text = ""
            for page in pdf.pages:
                text += page.extract_text() + "\n"
            return text.strip()
    except Exception as e:
        print(f"Error reading {pdf_path}: {e}", file=sys.stderr)
        return ""

def extract_text(pdf_path):
    """Extract text from PDF using available library"""
    if HAS_PDFPLUMBER:
        return extract_text_pdfplumber(pdf_path)
    elif HAS_PYPDF2:
        return extract_text_pypdf2(pdf_path)
    else:
        return ""

def main():
    # Get base directory from environment variable or command line argument
    base_dir_path = os.environ.get('WINE_DESCRIPTIONS_DIR')
    
    if len(sys.argv) > 1:
        base_dir_path = sys.argv[1]
    
    if not base_dir_path:
        print("Error: No wine descriptions directory specified", file=sys.stderr)
        print("Usage: export WINE_DESCRIPTIONS_DIR=\"/path/to/wine/descriptions\"", file=sys.stderr)
        print("       python3 extract_pdf_texts.py", file=sys.stderr)
        sys.exit(1)
    
    base_dir = Path(base_dir_path)
    if not base_dir.exists():
        print(f"Directory not found: {base_dir}", file=sys.stderr)
        sys.exit(1)
    
    wines_data = {}
    
    for wine_dir in sorted(base_dir.iterdir()):
        if not wine_dir.is_dir():
            continue
        
        wine_name = wine_dir.name
        descriptions = []
        
        for pdf_file in sorted(wine_dir.glob("*.pdf")):
            source_name = pdf_file.stem  # Filename without extension
            text = extract_text(pdf_file)
            
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
    if not HAS_PYPDF2 and not HAS_PDFPLUMBER:
        print("Error: No PDF library found. Please install PyPDF2 or pdfplumber:", file=sys.stderr)
        print("  pip3 install PyPDF2", file=sys.stderr)
        print("  or", file=sys.stderr)
        print("  pip3 install pdfplumber", file=sys.stderr)
        sys.exit(1)
    
    main()

