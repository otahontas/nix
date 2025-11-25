$env.LS_COLORS = (vivid generate rose-pine-dawn | str replace '*.lock=0;38;2;242;233;225' '*.lock=0;38;2;152;147;165')

$env.STARSHIP_SHELL = "nu"

source $"($nu.cache-dir)/carapace.nu"

$env.config.show_banner = false

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

def git-hooks-reset [] {
  let repo_root = (git rev-parse --show-toplevel | str trim)
  let template_hooks = $"($env.HOME)/.config/git/template/hooks"

  if not ($template_hooks | path exists) {
    print $"Error: Template hooks not found: ($template_hooks)"
    return
  }

  git config --unset core.hooksPath

  let hooks_dir = (git rev-parse --git-path hooks | str trim)
  mkdir $hooks_dir

  let existing = (ls $hooks_dir | where type == file)
  if ($existing | length) > 0 {
    let timestamp = (date now | format date "%Y%m%d%H%M%S")
    let backup_dir = $"($hooks_dir)/reset-backup-($timestamp)"
    mkdir $backup_dir
    $existing | each { |file| cp $file.name $backup_dir }
    print $"🗃  Existing hooks backed up to ($backup_dir)"
  }

  ls $template_hooks
    | where type == file
    | each { |hook|
        cp $hook.name $hooks_dir
        chmod +x $"($hooks_dir)/(($hook.name | path basename))"
      }

  print $"✅ Hooks reset using ($template_hooks)"
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
