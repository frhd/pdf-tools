#!/bin/bash

# update-ocr-info.sh
# Script to check PDFs for OCR text and update those without it

# Check if required parameters are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <input_directory> <output_directory>"
    echo "  <input_directory>: Directory containing PDF files to process"
    echo "  <output_directory>: Directory where processed PDFs will be saved"
    exit 1
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"

# Check if directories exist
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Input directory '$INPUT_DIR' does not exist"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Check for required tools
if ! command -v pdftotext &> /dev/null; then
    echo "Error: pdftotext not found. Please install poppler-utils."
    exit 1
fi

if ! command -v ocrmypdf &> /dev/null; then
    echo "Error: ocrmypdf not found. Please install ocrmypdf."
    exit 1
fi

# Process each PDF file in the input directory
echo "Processing PDF files in '$INPUT_DIR'..."
count_total=0
count_ocr_added=0
count_already_had_ocr=0

for pdf_file in "$INPUT_DIR"/*.pdf; do
    # Skip if no PDF files found
    [ -e "$pdf_file" ] || continue

    count_total=$((count_total + 1))
    filename=$(basename "$pdf_file")
    output_file="$OUTPUT_DIR/$filename"
    
    echo "Processing: $filename"
    
    # Check if PDF already has text
    word_count=$(pdftotext "$pdf_file" - | wc -w)
    
    if [ "$word_count" -gt 0 ]; then
        echo "  PDF already contains text. Copying to output directory."
        cp "$pdf_file" "$output_file"
        count_already_had_ocr=$((count_already_had_ocr + 1))
    else
        echo "  No text found in PDF. Applying OCR..."
        
        # Apply OCR using ocrmypdf
        ocrmypdf --deskew --clean --skip-text "$pdf_file" "$output_file"
        
        # Check if OCR was successful
        if [ $? -eq 0 ]; then
            echo "  OCR completed successfully."
            count_ocr_added=$((count_ocr_added + 1))
        else
            echo "  OCR failed. Copying original file to output directory."
            cp "$pdf_file" "$output_file"
        fi
    fi
done

# Print summary
echo ""
echo "Summary:"
echo "  Total PDFs processed: $count_total"
echo "  PDFs that already had OCR: $count_already_had_ocr"
echo "  PDFs where OCR was added: $count_ocr_added"
echo ""
echo "All processed PDFs saved to: $OUTPUT_DIR" 