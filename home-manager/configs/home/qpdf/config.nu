def combine-pdfs-in-folder [folder: string] {
  let folder_path = ($folder | path expand)

  if not ($folder_path | path exists) {
    error make {msg: $"Folder not found: ($folder_path)"}
  }

  if ($folder_path | path type) != "dir" {
    error make {msg: $"Path is not a directory: ($folder_path)"}
  }

  let pdf_files = (glob $"($folder_path)/*.pdf" | sort)

  if ($pdf_files | is-empty) {
    error make {msg: $"No PDF files found in ($folder_path)"}
  }

  let folder_name = ($folder_path | path basename)
  let parent_dir = ($folder_path | path dirname)
  let output_file = $"($parent_dir)/($folder_name).pdf"

  print $"Combining ($pdf_files | length) PDFs from ($folder_name)..."

  ^qpdf --empty --pages ...$pdf_files -- $output_file

  print $"✓ Combined PDF created: ($output_file)"
}
