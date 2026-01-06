# Helper to call OpenAI API
# TODO: a lot betterments needed:
# - regen iterative approach doesn't work well: what's better ux here? some sort of
# loop, piping to another command dunno?
# - should save the original prompt somehow to nushell history too
#
# also should split the file into smaller pieces (modules, nushell has support)
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

  # Re-run the command to capture the actual error message
  let result = (do { nu -c $last_cmd } | complete)
  let error = $result.stderr

  let user_prompt = $"CONTEXT:
- Shell: ($context.shell)
- OS: ($context.os)
- Current directory: ($context.cwd)

The following command failed:($last_cmd)

Error message:($error)

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
