{ ... }:
{
  # Catppuccin theme configuration
  # Change flavor to switch between light/dark themes
  # Flavors: "latte" (light), "frappe" (cool dark), "macchiato" (warm dark), "mocha" (deep dark)
  catppuccin = {
    enable = true;
    flavor = "latte"; # Change this to switch themes
    accent = "mauve"; # blue, flamingo, green, lavender, maroon, mauve, peach, pink, red, rosewater, sapphire, sky, teal, yellow
    eza.enable = false; # Disable eza theming since we don't use eza
  };
}
