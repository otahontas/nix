# Keybindings for AI command generation
# TODO: move to ai setup
$env.config.keybindings ++= [
  {
    name: ai_command_generate
    modifier: alt
    keycode: char_a
    mode: [vi_insert vi_normal]
    event: {
      send: executehostcommand
      cmd: "commandline edit --replace (ai-cmd (commandline))"
    }
  }
  {
    name: ai_fix_last_command
    modifier: alt_shift
    keycode: char_a
    mode: [vi_insert vi_normal]
    event: {
      send: executehostcommand
      cmd: "commandline edit --replace (ai-fix-last)"
    }
  }
]
