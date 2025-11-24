# Rosé Pine Dawn theme for Nushell
# Based on https://rosepinetheme.com/palette/ingredients/

let theme = {
  # Rosé Pine Dawn accent colors
  love: "#b4637a"      # Red tones
  gold: "#ea9d34"      # Yellow/gold
  rose: "#d7827e"      # Pink/rose
  pine: "#286983"      # Teal/cyan
  foam: "#56949f"      # Blue/foam
  iris: "#907aa9"      # Purple/iris

  # Base colors
  base: "#faf4ed"      # Main background
  surface: "#fffaf3"   # Slightly lighter surface
  overlay: "#f2e9e1"   # Overlays and borders

  # Text colors
  text: "#575279"      # Main text
  subtle: "#797593"    # Subtle text
  muted: "#9893a5"     # Muted/disabled text

  # Highlights
  highlight_low: "#f4ede8"   # Low emphasis highlight
  highlight_med: "#dfdad9"   # Medium emphasis highlight
  highlight_high: "#cecacd"  # High emphasis highlight
}

let scheme = {
  recognized_command: $theme.pine
  unrecognized_command: $theme.text
  constant: $theme.gold
  punctuation: $theme.subtle
  operator: $theme.foam
  string: $theme.rose
  virtual_text: $theme.muted
  variable: { fg: $theme.iris attr: i }
  filepath: $theme.gold
}

$env.config.color_config = {
  separator: { fg: $theme.muted attr: b }
  leading_trailing_space_bg: { fg: $theme.foam attr: u }
  header: { fg: $theme.text attr: b }
  row_index: $scheme.virtual_text
  record: $theme.text
  list: $theme.text
  hints: $scheme.virtual_text
  search_result: { fg: $theme.text bg: $theme.highlight_med }
  shape_closure: $theme.foam
  closure: $theme.foam
  shape_flag: { fg: $theme.love attr: i }
  shape_matching_brackets: { attr: u }
  shape_garbage: $theme.love
  shape_keyword: $theme.iris
  shape_match_pattern: $theme.rose
  shape_signature: $theme.foam
  shape_table: $scheme.punctuation
  cell-path: $scheme.punctuation
  shape_list: $scheme.punctuation
  shape_record: $scheme.punctuation
  shape_vardecl: $scheme.variable
  shape_variable: $scheme.variable
  empty: { attr: n }
  filesize: {||
    if $in < 1kb {
      $theme.foam
    } else if $in < 10kb {
      $theme.pine
    } else if $in < 100kb {
      $theme.gold
    } else if $in < 10mb {
      $theme.rose
    } else if $in < 100mb {
      $theme.love
    } else if $in < 1gb {
      $theme.iris
    } else {
      $theme.love
    }
  }
  duration: {||
    if $in < 1day {
      $theme.foam
    } else if $in < 1wk {
      $theme.pine
    } else if $in < 4wk {
      $theme.gold
    } else if $in < 12wk {
      $theme.rose
    } else if $in < 24wk {
      $theme.love
    } else if $in < 52wk {
      $theme.iris
    } else {
      $theme.love
    }
  }
  date: {|| (date now) - $in |
    if $in < 1day {
      $theme.foam
    } else if $in < 1wk {
      $theme.pine
    } else if $in < 4wk {
      $theme.gold
    } else if $in < 12wk {
      $theme.rose
    } else if $in < 24wk {
      $theme.love
    } else if $in < 52wk {
      $theme.iris
    } else {
      $theme.love
    }
  }
  shape_external: $scheme.unrecognized_command
  shape_internalcall: $scheme.recognized_command
  shape_external_resolved: $scheme.recognized_command
  shape_block: $scheme.recognized_command
  block: $scheme.recognized_command
  shape_custom: $theme.iris
  custom: $theme.iris
  background: $theme.base
  foreground: $theme.text
  cursor: { bg: $theme.rose fg: $theme.base }
  shape_range: $scheme.operator
  range: $scheme.operator
  shape_pipe: $scheme.operator
  shape_operator: $scheme.operator
  shape_redirection: $scheme.operator
  glob: $scheme.filepath
  shape_directory: $scheme.filepath
  shape_filepath: $scheme.filepath
  shape_glob_interpolation: $scheme.filepath
  shape_globpattern: $scheme.filepath
  shape_int: $scheme.constant
  int: $scheme.constant
  bool: $scheme.constant
  float: $scheme.constant
  nothing: $scheme.constant
  binary: $scheme.constant
  shape_nothing: $scheme.constant
  shape_bool: $scheme.constant
  shape_float: $scheme.constant
  shape_binary: $scheme.constant
  shape_datetime: $scheme.constant
  shape_literal: $scheme.constant
  string: $scheme.string
  shape_string: $scheme.string
  shape_string_interpolation: $theme.iris
  shape_raw_string: $scheme.string
  shape_externalarg: $scheme.string
}
$env.config.highlight_resolved_externals = true
$env.config.explore = {
    status_bar_background: { fg: $theme.text, bg: $theme.surface },
    command_bar_text: { fg: $theme.text },
    highlight: { fg: $theme.text, bg: $theme.highlight_med },
    status: {
        error: $theme.love,
        warn: $theme.gold,
        info: $theme.pine,
    },
    selected_cell: { bg: $theme.foam fg: $theme.base },
}
