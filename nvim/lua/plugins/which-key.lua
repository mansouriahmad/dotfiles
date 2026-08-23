return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Local Keymaps (which-key)",
    },
  },
  config = function()
    local wk = require("which-key")

    wk.setup({
      preset = "modern",
      delay = 500,          -- delay before showing which-key popup (ms)
      plugins = {
        marks = true,       -- shows a list of your marks on ' and `
        registers = true,   -- shows your registers on " in NORMAL or <C-r> in INSERT mode
        spelling = {
          enabled = true,   -- enabling this will show WhichKey when pressing z= to select spelling suggestions
          suggestions = 20, -- how many suggestions should be shown in the list?
        },
        presets = {
          operators = true,    -- adds help for operators like d, y, ...
          motions = true,      -- adds help for motions
          text_objects = true, -- help for text objects triggered after entering an operator
          windows = true,      -- default bindings on <c-w>
          nav = true,          -- misc bindings to work with windows
          z = true,            -- bindings for folds, spelling and others prefixed with z
          g = true,            -- bindings for prefixed with g
        },
      },
      win = {
        border = "rounded",
        padding = { 1, 2 }, -- extra window padding [top/bottom, right/left]
      },
      layout = {
        spacing = 6,    -- spacing between columns
      },
      show_help = true, -- show a help message in the command line for using WhichKey
      show_keys = true, -- show the currently pressed key and its label as a message in the command line
    })

    -- Define key groups for better organization
    wk.add({
      { "<leader>f", group = "file/find" },
      { "<leader>s", group = "search" },
      { "<leader>g", group = "git" },
      { "<leader>l", group = "lsp" },
      { "<leader>w", group = "workspace" },
      { "<leader>d", group = "diagnostics" },
      { "<leader>c", group = "code" },
      { "<leader>r", group = "rename/refactor" },
      { "<leader>t", group = "theme" },
      { "<leader>x", group = "trouble" },
      { "<leader>a", group = "claude" },
      { "<leader>j", group = "move" },
      { "<leader>k", group = "move" },
      { "<leader>m", group = "modify" },
      { "<leader>,", group = "toggle" },
      { "<leader>u", group = "ui" },
      { "<leader>q", group = "session" },
      { "<leader>p", group = "python" },
      { "<leader>gN", group = "neogit" },
      { "<leader>gd", group = "diff" },
    })

    -- Basic keymaps from keymaps.lua
    wk.add({
      { "<leader>e", desc = "Toggle NvimTree" },
      { "<leader>W", desc = "Save all files" },
      { "<leader>j", desc = "Move line down" },
      { "<leader>k", desc = "Move line up" },
      { "<leader>m", desc = "Delete until next _" },
      { "<leader>,", desc = "Toggle list mode" },
      { "<leader>um", desc = "Toggle markdown rendering" },
      { "<leader>ui", desc = "Toggle inline images" },
      { "H",         desc = "Go to beginning of line" },
      { "L",         desc = "Go to end of line" },
      { "<left>",    desc = "Previous buffer" },
      { "<right>",   desc = "Next buffer" },
      { "<C-p>",     desc = "Find files (Telescope)" },
      { "<F1>",      desc = "Escape" },
    })

    -- LSP-specific keymaps (these will show when LSP is attached)
    wk.add({
      { "g",          group = "goto" },
      { "gd",         desc = "Go to definition" },
      { "gD",         desc = "Go to declaration" },
      { "gi",         desc = "Go to implementation" },
      { "gr",         desc = "Go to references" },
      { "K",          desc = "Hover documentation" },
      { "<leader>ca", desc = "Code actions" },
      { "<leader>rn", desc = "Rename symbol" },
      { "<leader>f",  desc = "Format code" },
      { "<leader>d",  desc = "Open float diagnostic" },
      { "<leader>D",  desc = "Go to type definition" },
      { "<leader>ls", desc = "Document symbols" },
      { "<leader>lw", desc = "Workspace symbols" },
    })

    -- Telescope keymaps
    wk.add({
      { "<leader>sf", desc = "Find files" },
      { "<leader>sg", desc = "Live grep" },
      { "<leader>sh", desc = "Help tags" },
      { "<leader>sk", desc = "Keymaps" },
      { "<leader>sF", desc = "Filetypes" },
      { "<leader>sn", desc = "Find Neovim config files" },
      { "<leader>egS", desc = "Enhanced Git Status with Telescope" },
      { "<leader>th", desc = "Theme selector with live preview" },
      { "<leader>tn", desc = "Cycle to next theme" },
      { "<leader>tf", desc = "Theme selector (favorites only)" },
    })

    -- Telescope git keymaps (fugitive removed; use gitsigns + Neogit)
    wk.add({
      { "<leader>gs",  desc = "Git status (Telescope)" },
      { "<leader>gc",  desc = "Git commits (Telescope)" },
      { "<leader>gr",  desc = "Git branches (Telescope)" },
      { "<leader>gss", desc = "Git stash (Telescope)" },
    })

    -- Trouble keymaps
    wk.add({
      { "<leader>xx", desc = "Diagnostics (Trouble)" },
      { "<leader>xX", desc = "Buffer Diagnostics (Trouble)" },
      { "<leader>cs", desc = "Symbols (Trouble)" },
      { "<leader>cl", desc = "LSP Definitions / references / ... (Trouble)" },
      { "<leader>xL", desc = "Location List (Trouble)" },
      { "<leader>xQ", desc = "Quickfix List (Trouble)" },
    })

    -- DAP keymaps
    wk.add({
      { "<leader>db", desc = "Toggle Breakpoint" },
      { "<leader>dB", desc = "Conditional Breakpoint" },
      { "<leader>dc", desc = "Continue" },
      { "<leader>di", desc = "Step Into" },
      { "<leader>do", desc = "Step Over" },
      { "<leader>dO", desc = "Step Out" },
      { "<leader>dr", desc = "Toggle REPL" },
      { "<leader>dl", desc = "Run Last" },
      { "<leader>du", desc = "Toggle DAP UI" },
      { "<leader>dT", desc = "Terminate" },
      { "<leader>dh", desc = "Hover Variables" },
      { "<leader>dp", desc = "Preview" },
      { "<leader>dR", desc = "Debug Rust Target (picker)" },
      { "<leader>dt", desc = "Debug Test Under Cursor" },
      { "<leader>dN", desc = ".NET Debug (auto‑detect dll)" },

    })

    -- Session keymaps
    wk.add({
      { "<leader>qs", desc = "Restore Session (cwd)" },
      { "<leader>ql", desc = "Restore Last Session" },
      { "<leader>qd", desc = "Stop Session Recording" },
    })

    -- Diffview keymaps
    wk.add({
      { "<leader>gdo", desc = "Diff View Open" },
      { "<leader>gdH", desc = "File History (Diffview)" },
      { "<leader>gdC", desc = "Close Diff View" },
      { "<leader>gdR", desc = "Repo History (Diffview)" },
    })

    -- Neogit keymaps
    wk.add({
      { "<leader>gn", desc = "Neogit (Magit-like)" },
      { "<leader>gNc", desc = "Neogit Commit" },
      { "<leader>gNp", desc = "Neogit Push" },
      { "<leader>gNl", desc = "Neogit Pull" },
    })

    -- Visual mode keymaps
    wk.add({
      { "p",         desc = "Paste without yanking" },
      { "<leader>j", desc = "Move selection down" },
      { "<leader>k", desc = "Move selection up" },
    })

    -- Search keymaps
    wk.add({
      { "n",  desc = "Next search result (centered)" },
      { "N",  desc = "Previous search result (centered)" },
      { "*",  desc = "Search word under cursor (centered)" },
      { "#",  desc = "Search word under cursor backwards (centered)" },
      { "g*", desc = "Search word under cursor (partial match, centered)" },
    })
  end,
}
