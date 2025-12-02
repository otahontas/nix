$env.config.keybindings ++= [{
  name: skim_file_select
  modifier: control
  keycode: char_t
  mode: [emacs, vi_normal, vi_insert]
  event: {
    send: executehostcommand
    cmd: "commandline edit --insert (fd --type f --hidden --follow --exclude .git | sk --multi --preview 'bat --color=always --style=numbers --line-range=:500 {}' | str join ' ')"
  }
}]
$env.config.keybindings ++= [{
  name: skim_history_search
  modifier: control
  keycode: char_r
  mode: [emacs, vi_normal, vi_insert]
  event: {
    send: executehostcommand
    cmd: "commandline edit --replace (history | get command | reverse | sk --no-sort --tac | str trim)"
  }
}]
$env.config.keybindings ++= [{
  name: skim_directory_cd
  modifier: alt
  keycode: char_c
  mode: [emacs, vi_normal, vi_insert]
  event: {
    send: executehostcommand
    cmd: "cd (fd --type d --hidden --follow --exclude .git | sk --preview 'ls -la {}' | str trim)"
  }
}]
