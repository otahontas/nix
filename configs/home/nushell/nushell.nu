$env.SHELL = (which nu).path.0
$env.config.show_banner = false
$env.config.completions = {
  case_sensitive: false
  algorithm: "fuzzy"
  quick: true
  partial: true
  use_ls_colors: true
}
$env.config.history = {
  max_size: 10000
  sync_on_enter: true
  file_format: "sqlite"
  isolation: false
}
$env.config.edit_mode = "vi"
$env.config.cursor_shape = {
  vi_insert: line
  vi_normal: block
}
$env.config.keybindings ++= [
  {
    name: completion_menu
    modifier: none
    keycode: tab
    mode: [emacs vi_normal vi_insert]
    event: {
      until: [
        {send: menu name: completion_menu}
        {send: menunext}
        {edit: complete}
      ]
    }
  }
  {
    name: completion_previous
    modifier: shift
    keycode: backtab
    mode: [emacs vi_normal vi_insert]
    event: {send: menuprevious}
  }
  {
    name: insert_newline
    modifier: shift
    keycode: enter
    mode: [emacs vi_insert]
    event: {edit: insertnewline}
  }
]
def week [] { date now | format date "%U" }
def today [] { date now | format date "%F" }
def mcd [dir: string] {
  mkdir $dir
  cd $dir
}
def cl [dir: string] {
  cd $dir
  ls
}
def listening [pattern?: string] {
  let ports = (sudo lsof -iTCP -sTCP:LISTEN -n -P | from ssv)

  if ($pattern | is-empty) {
    $ports
  } else {
    $ports | where {|row|
      ($row | values | any {|val| ($val | into string) =~ $pattern })
    }
  }
}
def nukeport [port: int] {
  let pids = (lsof -ti :($port) | lines | uniq)

  if ($pids | is-empty) {
    print $"No process found on port ($port)"
    return
  }

  $pids | each {|pid|
    print $"Killing PID ($pid) on port ($port)"
    kill -9 ($pid | into int)
  }

  print $"✓ Port ($port) freed"
}
def myip [] {
  ifconfig
  | lines
  | where ($it | str contains "inet ")
  | where {|line| not ($line | str contains "127.0.0.1") }
  | each {|line| $line | str trim | split row ' ' | get 1 }
}
def daily [date?: string] {
  let notes_dir = $"($env.HOME)/Documents/notes/daily"

  let date_str = if ($date | is-empty) {
    date now | format date "%Y-%m-%d"
  } else {
    $date
  }

  let note_path = $"($notes_dir)/($date_str).md"
  mkdir $notes_dir

  if not ($note_path | path exists) {
    touch $note_path
  }

  if ($env.VISUAL? | is-not-empty) {
    ^$env.VISUAL $note_path
  } else if ($env.EDITOR? | is-not-empty) {
    ^$env.EDITOR $note_path
  } else {
    open $note_path
  }
}
def disable-sleep [] {
  sudo pmset -a disablesleep 1
}
def enable-sleep [] {
  sudo pmset -a disablesleep 0
}
def mac-open [
  --skip
  -a: string
  ...args: string
] {
  if ($args | is-empty) {
    error make {msg: "Usage: mac-open [--skip] [-a application] ...arguments"}
  }
  if $skip {
    ^/usr/bin/open ...$args
    return
  }
  if ($a | is-not-empty) {
    ^/usr/bin/open -a $a ...$args
    return
  }
  let file_path = $args.0
  if ($file_path | path exists) and ($file_path | path type) == "file" {
    let input_mime_type = (^file -b --mime-type $file_path | str trim)

    if ($input_mime_type | str starts-with "text/") or ($input_mime_type == "application/json") {
      ^$env.EDITOR ...$args
      return
    }
  }
  ^/usr/bin/open ...$args
}
def cleanup-cache [] {
  print "This will cleanup cache older than 6 months. Are you sure? [y/N]"
  let response = input

  if ($response | str downcase) in ["y" "yes"] {
    ^find ~/.cache/ -depth -type f -atime +182 -delete
    print "✓ Cache cleanup complete"
  } else {
    print "Cancelled"
  }
}
def trash-empty [] {
  print "Empty Trash? [y/N]"
  let response = input

  if ($response | str downcase) in ["y" "yes"] {
    ^osascript -e 'tell app "Finder" to empty'
    print "✓ Trash emptied"
  } else {
    print "Cancelled"
  }
}
alias la = ls -a
alias ll = ls -l
alias lla = ls -la
alias ... = cd ../..
alias .... = cd ../../..
