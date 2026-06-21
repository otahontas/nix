#!/usr/bin/env bash
set -euo pipefail

folder="$1"
folder_path=$(realpath "$folder" 2>/dev/null || echo "$folder")

if [ ! -e "$folder_path" ]; then
  echo "Error: Folder not found: $folder_path" >&2
  exit 1
fi

if [ ! -d "$folder_path" ]; then
  echo "Error: Path is not a directory: $folder_path" >&2
  exit 1
fi

mapfile -d '' -t pdf_files < <(fd -0 -e pdf -t f -d 1 . "$folder_path" | sort -z)

if [ "${#pdf_files[@]}" -eq 0 ]; then
  echo "Error: No PDF files found in $folder_path" >&2
  exit 1
fi

folder_name=$(basename "$folder_path")
parent_dir=$(dirname "$folder_path")
output_file="$parent_dir/$folder_name.pdf"

pdf_count=${#pdf_files[@]}
echo "Combining $pdf_count PDFs from $folder_name..."

qpdf --empty --pages "${pdf_files[@]}" -- "$output_file"

echo "✓ Combined PDF created: $output_file"
