local wezterm = require("wezterm")

local config = {
  -- Frappé over Mocha: same Catppuccin palette, but the base is lifted
  -- (#1e1e2e -> #303446) and the fg dimmed (#cdd6f4 -> #c6d0f5). Drops text
  -- contrast ~11.3:1 -> ~8.1:1, still clear of WCAG AAA (7:1), with less glare
  -- on long sessions. Note: this build only knows the unaccented name.
  color_scheme = "Catppuccin Frappe",
  font = wezterm.font("JetBrainsMono Nerd Font"), -- Nerd Font: icons + ligatures
  font_size = 12.5,

  -- Opaque, not 0.95: translucency composited by the software renderer below
  -- blurs glyph edges and makes contrast depend on whatever is behind the
  -- window. Blur is fatiguing independently of contrast.
  window_background_opacity = 1.0,
  -- Lighter hinting: softer stems than the default, which suits a dimmed fg.
  freetype_load_target = "Light",

  enable_tab_bar = false, -- zellij handles tabs
}

if wezterm.target_triple:find("linux") then
  -- Headless GNOME/RDP session: Wayland explicit-sync path crashes
  -- (no dmabuf in software rendering). Force XWayland + software renderer.
  -- Linux only: on macOS the GPU front end works and is much faster.
  config.enable_wayland = false
  config.front_end = "Software"
end

return config
