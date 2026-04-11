{ pkgs, ... }:
let
  combine-pdfs-in-folder = pkgs.writeShellScriptBin "combine-pdfs-in-folder" ''
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

    pdf_files=$(fd -e pdf -t f -d 1 . "$folder_path" | sort)

    if [ -z "$pdf_files" ]; then
      echo "Error: No PDF files found in $folder_path" >&2
      exit 1
    fi

    folder_name=$(basename "$folder_path")
    parent_dir=$(dirname "$folder_path")
    output_file="$parent_dir/$folder_name.pdf"

    pdf_count=$(echo "$pdf_files" | wc -l | tr -d ' ')
    echo "Combining $pdf_count PDFs from $folder_name..."

    qpdf --empty --pages $pdf_files -- "$output_file"

    echo "✓ Combined PDF created: $output_file"
  '';
in
{
  home = {
    packages = [ pkgs.qpdf combine-pdfs-in-folder ];
  };
}
