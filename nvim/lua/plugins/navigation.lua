-- Seamless Ctrl-hjkl across Neovim windows and Zellij panes.
--
-- Zellij sees keys first, so ~/.config/zellij/config.kdl binds Ctrl-hjkl to the
-- vim-zellij-navigator wasm plugin. That plugin forwards the key to Neovim when a
-- vim process owns the pane; smart-splits moves the cursor, and when there is no
-- window in that direction it hands control back to Zellij to move the pane.
-- Replaces vim-tmux-navigator, which went away with tmux.
return {
  'mrjones2014/smart-splits.nvim',
  lazy = false,
  config = function()
    require('smart-splits').setup({ multiplexer_integration = 'zellij' })

    local ss = require('smart-splits')
    local map = function(lhs, rhs, desc)
      vim.keymap.set('n', lhs, rhs, { desc = desc })
    end

    map('<C-h>', ss.move_cursor_left, 'Move focus left (window or Zellij pane)')
    map('<C-j>', ss.move_cursor_down, 'Move focus down (window or Zellij pane)')
    map('<C-k>', ss.move_cursor_up, 'Move focus up (window or Zellij pane)')
    map('<C-l>', ss.move_cursor_right, 'Move focus right (window or Zellij pane)')

    -- Zellij cannot resize by a specific amount, so these are direction-only there.
    map('<A-h>', ss.resize_left, 'Resize left')
    map('<A-j>', ss.resize_down, 'Resize down')
    map('<A-k>', ss.resize_up, 'Resize up')
    map('<A-l>', ss.resize_right, 'Resize right')

    -- Terminal buffers (Claude Code, toggleterm) start in insert mode, where the
    -- normal-mode maps never fire. The Claude split sits on the right, so left is
    -- the only direction needed. <C-j>/<C-k>/<C-l> stay unmapped on purpose: the
    -- Claude TUI uses them (newline, clear) and stealing them breaks typing.
    vim.keymap.set('t', '<C-h>', function()
      vim.cmd('stopinsert')
      ss.move_cursor_left()
    end, { desc = 'Terminal: move focus left' })
  end,
}
