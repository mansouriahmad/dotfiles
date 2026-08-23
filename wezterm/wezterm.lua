local wezterm = require("wezterm")

return {
  color_scheme = "Catppuccin Mocha",
  font = wezterm.font("JetBrainsMono Nerd Font"), -- Nerd Font: icons + ligatures
  font_size = 12.5,
  window_background_opacity = 0.95,

  enable_tab_bar = false, -- zellij handles tabs

  -- Headless GNOME/RDP session: Wayland explicit-sync path crashes
  -- (no dmabuf in software rendering). Force XWayland + software renderer.
  enable_wayland = false,
  front_end = "Software",
}
