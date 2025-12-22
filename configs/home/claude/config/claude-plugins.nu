def claude-update-all [] {
  print "Updating marketplaces..."
  ^claude plugin marketplace update

  let plugins_file = $"($env.HOME)/.claude/plugins/installed_plugins.json"

  if not ($plugins_file | path exists) {
    print "No installed plugins found"
    return
  }

  let plugins = (open $plugins_file | get plugins | columns)
  let total = ($plugins | length)

  print $"Updating ($total) plugins..."

  mut success = 0
  mut failed = []

  for plugin in $plugins {
    print $"  Updating ($plugin)..."
    let result = (^claude plugin install $plugin | complete)
    if $result.exit_code == 0 {
      $success = $success + 1
    } else {
      $failed = ($failed | append $plugin)
    }
  }

  print ""
  print $"Done: ($success)/($total) plugins updated"

  if ($failed | length) > 0 {
    print "Failed:"
    for f in $failed {
      print $"  - ($f)"
    }
  }

  print ""
  print "Restart Claude Code to load updates"
}
