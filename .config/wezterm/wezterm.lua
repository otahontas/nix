local wezterm = require("wezterm")

local keys = {
  -- claude code shift enter
  { key = "Enter", mods = "SHIFT", action = wezterm.action { SendString = "\x1b\r", }, },
  -- open splits
  {
    key = "v",
    mods = "LEADER",
    action = wezterm.action({ SplitHorizontal = { domain = "CurrentPaneDomain", }, }),
  },
  {
    key = "s",
    mods = "LEADER",
    action = wezterm.action({ SplitVertical = { domain = "CurrentPaneDomain", }, }),
  },
  {
    key = "w",
    mods = "LEADER",
    action = wezterm.action({ CloseCurrentPane = { confirm = true, }, }),
  },
  -- move between splits
  {
    key = "h",
    mods = "LEADER",
    action = wezterm.action({ ActivatePaneDirection = "Left", }),
  },
  {
    key = "j",
    mods = "LEADER",
    action = wezterm.action({ ActivatePaneDirection = "Down", }),
  },
  {
    key = "k",
    mods = "LEADER",
    action = wezterm.action({ ActivatePaneDirection = "Up", }),
  },
  {
    key = "l",
    mods = "LEADER",
    action = wezterm.action({ ActivatePaneDirection = "Right", }),
  },
  -- resize splits with shift
  {
    key = "h",
    mods = "LEADER | SHIFT",
    action = wezterm.action({ AdjustPaneSize = { "Left", 5, }, }),
  },
  {
    key = "j",
    mods = "LEADER | SHIFT",
    action = wezterm.action({ AdjustPaneSize = { "Down", 5, }, }),
  },
  {
    key = "k",
    mods = "LEADER | SHIFT",
    action = wezterm.action({ AdjustPaneSize = { "Up", 5, }, }),
  },
  {
    key = "l",
    mods = "LEADER | SHIFT",
    action = wezterm.action({
      AdjustPaneSize = {
        "Right",
        5,
      },
    }),
  },
  -- open new tab
  {
    key = "c",
    mods = "LEADER",
    action = wezterm.action({ SpawnTab = "CurrentPaneDomain", }),
  },
  -- move between tabs
  {
    key = "n",
    mods = "LEADER",
    action = wezterm.action({ ActivateTabRelative = 1, }),
  },
  {
    key = "p",
    mods = "LEADER",
    action = wezterm.action({ ActivateTabRelative = -1, }),
  },
  -- search
  {
    key = "f",
    mods = "LEADER",
    action = wezterm.action({ Search = { CaseSensitiveString = "", }, }),
  },
  -- scroll pages
  {
    key = "u",
    mods = "LEADER",
    action = wezterm.action({ ScrollByPage = -1, }),
  },
  {
    key = "d",
    mods = "LEADER",
    action = wezterm.action({ ScrollByPage = 1, }),
  },
}

return {
  -- aesthetics
  color_scheme = "Catppuccin Mocha",
  font = wezterm.font("JetBrainsMono Nerd Font"),
  font_size = 13,
  hide_tab_bar_if_only_one_tab = false,
  tab_bar_at_bottom = true,
  use_fancy_tab_bar = false,
  window_decorations = "INTEGRATED_BUTTONS|RESIZE",
  -- logic
  leader = { key = "a", mods = "CTRL", },
  keys = keys,
}
