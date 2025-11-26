$env.SHELL = (which nu).path.0
$env.STARSHIP_SHELL = "nu"

source $"($nu.cache-dir)/carapace.nu"

$env.config.show_banner = false

$env.config.completions.case_sensitive = false
$env.config.completions.algorithm = "substring"

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

alias ... = cd ../..
alias .... = cd ../../..
alias la = ls -a
alias ll = ls -l
alias lla = ls -la
alias cat = bat
alias todo = nvim ~/Documents/todo/todo.txt
alias gsw = git sw

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
    $ports | where { |row|
      ($row | values | any { |val| ($val | into string) =~ $pattern })
    }
  }
}

def myip [] {
  ifconfig
    | lines
    | where ($it | str contains "inet ")
    | where ($it | str contains "127.0.0.1" | not $in)
    | each { |line| $line | parse "inet {ip} " | get ip.0 }
}

def find-and-prune [pattern: string] {
  print $"This will delete all files/directories matching: ($pattern)"
  let response = (input "Are you sure? [y/N] ")

  if ($response | str downcase) in ["y", "yes"] {
    fd -H $pattern --exec rm -rf
  } else {
    print "Cancelled"
  }
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

def lefthook-setup [] {
  let repo_root = (git rev-parse --show-toplevel | str trim)
  let template = $"($env.HOME)/.config/git/lefthook.yml"

  if not ($template | path exists) {
    print $"Error: Template not found: ($template)"
    return
  }

  let lefthook_file = $"($repo_root)/lefthook.yml"

  if ($lefthook_file | path exists) {
    let response = (input "lefthook.yml already exists. Overwrite? [y/N] ")
    if ($response | str downcase) not-in ["y", "yes"] {
      print "Cancelled"
      return
    }
  }

  cp $template $lefthook_file
  chmod a+x $lefthook_file
  print $"📝 Created lefthook.yml"

  lefthook install
  print $"✅ Lefthook installed in ($repo_root)"
}

def gh-release-slack [pr_number: int] {
  let pr_data = (^gh pr view $pr_number --json title,body --template '{{ .title }}{{"\n"}}{{ .body }}' | complete)

  if $pr_data.exit_code != 0 or ($pr_data.stdout | is-empty) {
    error make {msg: $"Failed to read PR ($pr_number)."}
  }

  let lines = ($pr_data.stdout | lines)
  let title = ($lines | first)
  let release_notes = ($lines | skip 1 | str join "\n")

  let regex_match = ($title | parse -r '^Release\s+(.+?)\s+(\S+)$')

  if ($regex_match | is-empty) {
    error make {msg: $"PR ($pr_number) title \"($title)\" does not match \"Release <service> <version>\" format."}
  }

  let service = ($regex_match | get capture0.0 | str trim)
  let version = ($regex_match | get capture1.0)

  if ($release_notes | str trim | is-empty) {
    error make {msg: $"PR ($pr_number) release notes are empty."}
  }

  let output = $"Release ($service) `($version)`\n\n($release_notes)"

  print $output

  if (which pbcopy | is-not-empty) {
    try {
      $output | pbcopy
      print -e "Copied to clipboard."
    } catch {
      print -e "Failed to copy to clipboard."
    }
  } else {
    print -e "pbcopy not available; clipboard copy skipped."
  }
}

def mac-open [...args: string] {
  if ($args | is-empty) {
    error make {msg: "Usage: mac-open [--skip] [-a application] ...arguments"}
  }

  # If "--skip" flag is provided, remove it and proceed
  if ($args.0 == "--skip") {
    ^/usr/bin/open ...($args | skip 1)
    return
  }

  # If "-a" flag is provided, assume it's an app launch and bypass text handling
  if ($args.0 == "-a") {
    ^/usr/bin/open ...$args
    return
  }

  # Check if the first argument is a file and get its MIME type
  let file_path = $args.0
  if ($file_path | path exists) and ($file_path | path type) == "file" {
    let input_mime_type = (^file -b --mime-type $file_path | str trim)

    if ($input_mime_type | str starts-with "text/") or ($input_mime_type == "application/json") {
      ^$env.EDITOR ...$args
      return
    }
  }

  # Otherwise, open the file in the default application
  ^/usr/bin/open ...$args
}

# Initialize Starship prompt
def create_left_prompt [] {
  starship prompt --cmd-duration $env.CMD_DURATION_MS --status $env.LAST_EXIT_CODE
}

def create_right_prompt [] {
  ""
}

$env.PROMPT_COMMAND = { || create_left_prompt }
$env.PROMPT_COMMAND_RIGHT = { || create_right_prompt }

# LLM command completion keybinding (Alt-\)
$env.config.keybindings ++= [{
  name: llm_cmdcomp
  modifier: alt
  keycode: char_\
  mode: [emacs, vi_normal, vi_insert]
  event: {
    send: executehostcommand
    cmd: "commandline edit --replace (commandline | llm -s 'You are a shell command generator for macOS using Nushell. Convert the user request into a valid shell command. Return ONLY the command, no explanation, no markdown, no code blocks. Just the raw command that can be executed in Nushell.' | str trim)"
  }
}]
