alias c = claude
alias cc = claude -c
alias cr = claude -r
alias colo = claude --dangerously-skip-permissions
alias ccolo = claude -c --dangerously-skip-permissions
alias crolo = claude -r --dangerously-skip-permissions

# Helper to call OpenAI API
def ai-call [messages: list]: nothing -> string {
  let api_key = (^pass show api/openai-shell-ai | lines | first)

  let body = {
    model: "gpt-4o-mini"
    max_tokens: 256
    messages: $messages
  }

  let result = (
    http post https://api.openai.com/v1/chat/completions
    --content-type application/json
    --headers [Authorization $"Bearer ($api_key)"]
    $body
  )

  $result.choices.0.message.content | str trim
}

# Check if command has valid nushell syntax
def ai-lint [cmd: string]: nothing -> record<valid: bool, error: string> {
  let result = (do { nu -c $cmd } | complete)
  {
    valid: ($result.exit_code == 0)
    error: $result.stderr
  }
}

# Build context for AI prompts
def ai-context []: nothing -> record<shell: string, os: string, cwd: string, history: string> {
  {
    shell: "nushell"
    os: (sys host | get name)
    cwd: (pwd)
    history: (history | last 10 | get command | to text)
  }
}

const AI_SYSTEM_PROMPT = "You are a shell command generator. Convert natural language to nushell commands.

RULES:
- Output ONLY the command, no explanations, no markdown, no backticks
- Use nushell syntax, not bash
- Always generate the command even if you're unsure if tools are installed - let the user handle that
- Only output ERROR: <reason> if the request itself is completely nonsensical"

# Generate command from natural language, with one lint+retry if syntax fails
def ai-cmd [query: string]: nothing -> string {
  let context = (ai-context)

  let user_prompt = $"CONTEXT:
- Shell: ($context.shell)
- OS: ($context.os)
- Current directory: ($context.cwd)
- Recent commands:($context.history)

REQUEST: ($query)"

  let messages = [
    {role: "system" content: $AI_SYSTEM_PROMPT}
    {role: "user" content: $user_prompt}
  ]

  let output = (ai-call $messages)

  if ($output | str starts-with "ERROR:") {
    error make {msg: ($output | str replace "ERROR: " "")}
  }

  # Lint check - if syntax fails, retry once with error context
  let lint = (ai-lint $output)
  if $lint.valid {
    return $output
  }

  let retry_messages = (
    $messages | append [
      {role: "assistant" content: $output}
      {role: "user" content: $"That command has a syntax error: ($lint.error)\n\nPlease fix it. Output ONLY the corrected command."}
    ]
  )

  let fixed = (ai-call $retry_messages)
  $fixed
}

# Fix the last failed command using its error output
def ai-fix-last []: nothing -> string {
  let last_cmd = (history | last 1 | get command | first)
  let context = (ai-context)

  let user_prompt = $"CONTEXT:
- Shell: ($context.shell)
- OS: ($context.os)
- Current directory: ($context.cwd)

The following command failed:($last_cmd)

Please provide a corrected version. Output ONLY the fixed command, no explanations."

  let messages = [
    {role: "system" content: $AI_SYSTEM_PROMPT}
    {role: "user" content: $user_prompt}
  ]

  let output = (ai-call $messages)

  if ($output | str starts-with "ERROR:") {
    error make {msg: ($output | str replace "ERROR: " "")}
  }

  $output
}

# Keybindings for AI command generation
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
