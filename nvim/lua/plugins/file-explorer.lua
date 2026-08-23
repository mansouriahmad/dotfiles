return {
  {
    'stevearc/oil.nvim',
    -- dependencies = { { "echasnovski/mini.icons", opts = {} } },
    dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    config = function()
      require('oil').setup {
        columns = { "icon" },
        keymaps = {
          ["<C-h>"] = false,
          ["<M-h>"] = "actions.select_split"
        },
        vim_options = {
          show_hidden = true,
        }
      }
      vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open current directory" })
      vim.keymap.set("n", "<leader>-", require("oil").toggle_float)
    end,
    lazy = false,

  },
  -- {
  --   'stevearc/oil.nvim',
  --   ---@module 'oil'
  --   ---@type oil.SetupOpts
  --   opts = {
  --     -- Oil will take over directory buffers (e.g. `vim .` or `:e src/`)
  --     -- Set to false if you still want to use netrw.
  --     default_file_explorer = true,
  --     -- Id is automatically added at the beginning, and name at the end
  --     -- See :help oil-columns
  --     columns = {
  --       "icon",
  --       -- "permissions",
  --       -- "size",
  --       -- "mtime",
  --     },
  --     -- Buffer-local options to use for oil buffers
  --     buf_options = {
  --       buflisted = false,
  --       bufhidden = "hide",
  --     },
  --     -- Window-local options to use for oil buffers
  --     win_options = {
  --       wrap = false,
  --       signcolumn = "no",
  --       cursorcolumn = false,
  --       foldcolumn = "0",
  --       spell = false,
  --       list = false,
  --       conceallevel = 3,
  --       concealcursor = "nvic",
  --     },
  --     -- Restore window options to previous values when leaving an oil buffer
  --     restore_win_options = true,
  --     -- Skip the confirmation popup for simple operations
  --     skip_confirm_for_simple_edits = false,
  --     -- Keymaps in oil buffer. Can be any value that `vim.keymap.set` accepts
  --     keymaps = {
  --       ["g?"] = "show_help",
  --       ["<CR>"] = "select",
  --       ["<C-s>"] = "select_vsplit",
  --       ["<C-h>"] = "select_split",
  --       ["<C-t>"] = "select_tab",
  --       ["<C-p>"] = "preview",
  --       ["<C-c>"] = "close",
  --       ["<C-l>"] = "refresh",
  --       ["-"] = "parent",
  --       ["_"] = "cd",
  --       ["`"] = "cd ..",
  --       ["~"] = "tcd",
  --       ["gs"] = "change_sort",
  --       ["gx"] = "open_external",
  --       ["g."] = "toggle_hidden",
  --       ["g\\"] = "toggle_trash",
  --     },
  --     -- Set to false to disable all of the above keymaps
  --     use_default_keymaps = true,
  --     -- Set to true to load directories on demand. This can reduce startup time.
  --     -- It may cause some side effects.
  --     -- See :help oil-columns
  --     load_default_actions = true,
  --     -- Set to true to use the column-based implementation. This is a lot
  --     -- faster, but the display is not as customizable. You can't do things
  --     -- like add a custom column or change the default columns.
  --     -- See :help oil-columns
  --     view_options = {
  --       -- Show files and directories that start with "."
  --       show_hidden = false,
  --       -- This function defines what is considered a "hidden" file
  --       is_hidden_file = function(name, bufnr)
  --         return vim.startswith(name, ".")
  --       end,
  --       -- This function defines what will never be shown, even when `show_hidden` is set
  --       is_always_hidden = function(name, bufnr)
  --         return false
  --       end,
  --       sort = {
  --         -- sort order can be "asc" or "desc"
  --         -- see :help oil-columns to see which columns are sortable
  --         { "type", "asc" },
  --         { "name", "asc" },
  --       },
  --     },
  --     -- Configuration for the floating window in oil.open_float
  --     float = {
  --       -- Padding around the floating window
  --       padding = 2,
  --       max_width = 0,
  --       max_height = 0,
  --       border = "rounded",
  --       win_options = {
  --         winblend = 0,
  --       },
  --       -- This is the config that will be passed to nvim_open_win.
  --       -- Change values here to customize the layout
  --       override = function(conf)
  --         return conf
  --       end,
  --     },
  --     -- Configuration for the actions floating window
  --     preview = {
  --       -- Width dimensions can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
  --       -- min_width and max_width can be a single value or a list of mixed integer/float types.
  --       -- max_width = {100, 0.8} means "the lesser of 100 columns or 80% of total"
  --       max_width = 0.9,
  --       -- min_width = {40, 0.4} means "the greater of 40 columns or 40% of total"
  --       min_width = { 40, 0.4 },
  --       -- optionally define an integer/float for the exact width of the preview window
  --       width = nil,
  --       -- Height dimensions can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
  --       -- min_height and max_height can be a single value or a list of mixed integer/float types.
  --       max_height = 0.9,
  --       min_height = { 5, 0.1 },
  --       -- optionally define an integer/float for the exact height of the preview window
  --       height = nil,
  --       border = "rounded",
  --       win_options = {
  --         winblend = 0,
  --       },
  --       -- Whether the preview window is automatically updated when the cursor is moved
  --       update_on_cursor_moved = true,
  --     },
  --     -- Configuration for the floating progress window
  --     progress = {
  --       max_width = 0.9,
  --       min_width = { 40, 0.4 },
  --       width = nil,
  --       max_height = { 10, 0.9 },
  --       min_height = { 5, 0.1 },
  --       height = nil,
  --       border = "rounded",
  --       minimized_border = "none",
  --       win_options = {
  --         winblend = 0,
  --       },
  --     },
  --   },
  --   -- Optional dependencies
  --   dependencies = { { "echasnovski/mini.icons", opts = {} } },
  --   -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
  --   -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
  --   lazy = false,
  -- },
  -- {
  --   "nvim-tree/nvim-tree.lua",
  --   version = "*",
  --   lazy = false,
  --   dependencies = {
  --     "nvim-tree/nvim-web-devicons",
  --   },
  --   config = function()
  --     require("nvim-tree").setup {
  --       on_attach = function(bufnr)
  --         local api = require("nvim-tree.api")

  --         -- Default mappings
  --         api.config.mappings.default_on_attach(bufnr)

  --         -- Remove conflicting mappings if they exist
  --         pcall(vim.keymap.del, 'n', '<C-j>', { buffer = bufnr })
  --         pcall(vim.keymap.del, 'n', '<C-k>', { buffer = bufnr })
  --       end,
  --     }
  --   end

  -- }
}
