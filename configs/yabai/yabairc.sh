#!/usr/bin/env sh

# Use full path to yabai for launchd compatibility
YABAI="@yabai_bin@"

# Ignore specific apps
$YABAI -m rule --add app="^System Settings$" manage=off
$YABAI -m rule --add app="^Finder$" manage=off
$YABAI -m rule --add app="^Activity Monitor$" manage=off
