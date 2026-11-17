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
elseif wezterm.target_triple:find("windows") then
  -- No zellij on Windows, so WezTerm itself does tabs and panes, with the
  -- zellij bindings kept where they map: Ctrl-hjkl moves between nvim splits
  -- and WezTerm panes as one space (smart-splits sets the IS_NVIM user var and
  -- uses the wezterm integration on Windows), Alt-hjkl resizes.
  local act = wezterm.action

  local pwsh = "C:\\Program Files\\PowerShell\\7\\pwsh.exe"
  config.default_prog = { #wezterm.glob(pwsh) > 0 and pwsh or "powershell.exe", "-NoLogo" }

  config.enable_tab_bar = true
  config.use_fancy_tab_bar = false
  config.hide_tab_bar_if_only_one_tab = true

  -- RDP sessions without a GPU: set WEZTERM_FRONT_END=Software.
  if os.getenv("WEZTERM_FRONT_END") then
    config.front_end = os.getenv("WEZTERM_FRONT_END")
  end

  local function is_vim(pane)
    return pane:get_user_vars().IS_NVIM == "true"
  end

  -- Send the key to nvim when it owns the pane, otherwise act on WezTerm.
  local function nav(key, mods, action)
    return {
      key = key,
      mods = mods,
      action = wezterm.action_callback(function(win, pane)
        if is_vim(pane) then
          win:perform_action(act.SendKey({ key = key, mods = mods }), pane)
        else
          win:perform_action(action, pane)
        end
      end),
    }
  end

  config.keys = {
    -- Same keys as zellij/config.kdl where WezTerm has the action.
    { key = "n", mods = "ALT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
    { key = "d", mods = "ALT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
    { key = "x", mods = "ALT", action = act.CloseCurrentPane({ confirm = true }) },
    { key = "f", mods = "ALT", action = act.TogglePaneZoomState },
    { key = "t", mods = "ALT", action = act.SpawnTab("CurrentPaneDomain") },
    { key = "LeftArrow", mods = "ALT", action = act.ActivateTabRelative(-1) },
    { key = "RightArrow", mods = "ALT", action = act.ActivateTabRelative(1) },
    { key = "s", mods = "CTRL", action = act.ActivateCopyMode },
  }
  for key, dir in pairs({ h = "Left", j = "Down", k = "Up", l = "Right" }) do
    table.insert(config.keys, nav(key, "CTRL", act.ActivatePaneDirection(dir)))
    table.insert(config.keys, nav(key, "ALT", act.AdjustPaneSize({ dir, 3 })))
  end
end

return config
