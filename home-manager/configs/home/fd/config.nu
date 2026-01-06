# Find files or directories and delete those
def find-and-prune [pattern: string] {
  print $"This will delete all files/directories matching: ($pattern)"
  let response = (input "Are you sure? [y/N] ")
  if ($response | str downcase) in ["y" "yes"] {
    fd -H $pattern --exec rm -rf
  } else {
    print "Cancelled"
  }
}
