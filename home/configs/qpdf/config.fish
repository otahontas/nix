function combine-pdfs-in-folder --argument folder
    set folder_path (realpath "$folder" 2>/dev/null || echo "$folder")

    if not test -e "$folder_path"
        echo "Error: Folder not found: $folder_path" >&2
        return 1
    end

    if not test -d "$folder_path"
        echo "Error: Path is not a directory: $folder_path" >&2
        return 1
    end

    set pdf_files (fd -e pdf -t f -d 1 . "$folder_path" | sort)

    if test -z "$pdf_files"
        echo "Error: No PDF files found in $folder_path" >&2
        return 1
    end

    set folder_name (basename "$folder_path")
    set parent_dir (dirname "$folder_path")
    set output_file "$parent_dir/$folder_name.pdf"

    set pdf_count (count $pdf_files)
    echo "Combining $pdf_count PDFs from $folder_name..."

    qpdf --empty --pages $pdf_files -- "$output_file"

    echo "✓ Combined PDF created: $output_file"
end
