#!/bin/bash

# pdf-stats.sh
# Script to gather statistics about PDFs in a directory

# Check if required parameter is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <pdf_directory>"
    echo "  <pdf_directory>: Directory containing PDF files to analyze"
    exit 1
fi

PDF_DIR="$1"

# Check if directory exists
if [ ! -d "$PDF_DIR" ]; then
    echo "Error: Directory '$PDF_DIR' does not exist"
    exit 1
fi

# Check for required tools
if ! command -v pdfinfo &> /dev/null; then
    echo "Error: pdfinfo not found. Please install poppler-utils."
    exit 1
fi

if ! command -v pdftotext &> /dev/null; then
    echo "Error: pdftotext not found. Please install poppler-utils."
    exit 1
fi

# Initialize counters
total_pdfs=0
ocr_pdfs=0
no_ocr_pdfs=0
total_pages=0
largest_pdf_size=0
largest_pdf_name=""
smallest_pdf_size=9999999999
smallest_pdf_name=""
total_size_kb=0
encrypted_pdfs=0
searchable_pdfs=0

echo "Analyzing PDFs in '$PDF_DIR'..."
echo "This may take a while for large collections..."
echo ""

# Process each PDF file in the directory
for pdf_file in "$PDF_DIR"/*.pdf; do
    # Skip if no PDF files found
    [ -e "$pdf_file" ] || continue
    
    filename=$(basename "$pdf_file")
    total_pdfs=$((total_pdfs + 1))
    
    # Get file size in KB
    size_kb=$(du -k "$pdf_file" | cut -f1)
    total_size_kb=$((total_size_kb + size_kb))
    
    # Track largest and smallest PDFs
    if [ "$size_kb" -gt "$largest_pdf_size" ]; then
        largest_pdf_size=$size_kb
        largest_pdf_name=$filename
    fi
    
    if [ "$size_kb" -lt "$smallest_pdf_size" ]; then
        smallest_pdf_size=$size_kb
        smallest_pdf_name=$filename
    fi
    
    # Get basic PDF info
    if pdf_info=$(pdfinfo "$pdf_file" 2>/dev/null); then
        # Extract page count
        pages=$(echo "$pdf_info" | grep "Pages:" | awk '{print $2}')
        total_pages=$((total_pages + pages))
        
        # Check if encrypted
        if echo "$pdf_info" | grep -q "Encrypted: yes"; then
            encrypted_pdfs=$((encrypted_pdfs + 1))
        fi
    fi
    
    # Check if PDF has text (OCR or native)
    if word_count=$(pdftotext "$pdf_file" - 2>/dev/null | wc -w) && [ "$word_count" -gt 0 ]; then
        ocr_pdfs=$((ocr_pdfs + 1))
        searchable_pdfs=$((searchable_pdfs + 1))
    else
        no_ocr_pdfs=$((no_ocr_pdfs + 1))
    fi
    
    # Show progress for large collections
    if [ $((total_pdfs % 10)) -eq 0 ]; then
        echo -ne "Processed $total_pdfs PDFs...\r"
    fi
done

echo ""
echo "=== PDF STATISTICS ==="
echo "Total PDFs: $total_pdfs"
echo ""
echo "Content Analysis:"
echo "  PDFs with text (searchable): $ocr_pdfs ($(($ocr_pdfs * 100 / $total_pdfs))%)"
echo "  PDFs without text: $no_ocr_pdfs ($(($no_ocr_pdfs * 100 / $total_pdfs))%)"
echo "  Encrypted PDFs: $encrypted_pdfs"
echo ""
echo "Page Statistics:"
echo "  Total pages: $total_pages"
echo "  Average pages per PDF: $(($total_pages / $total_pdfs))"
echo ""
echo "Size Statistics:"
echo "  Total size: $(($total_size_kb / 1024)) MB"
echo "  Average size: $(($total_size_kb / $total_pdfs)) KB"
echo "  Largest PDF: $largest_pdf_name ($(($largest_pdf_size / 1024)) MB)"
echo "  Smallest PDF: $smallest_pdf_name ($smallest_pdf_size KB)"
echo ""
echo "Analysis complete!" 