return {
  'nvim-telescope/telescope.nvim',
  --keys = {
  --  {"<leader>sfkVjj", "<cmd>Telescope find_files<cr>"},
  -- {"<leader>sg", "<cmd>Telescope live_grep<cr>"},

  --},
  tag = '0.1.8',
  lazy = false,
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope-ui-select.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = (function()
        if vim.fn.has("win32") == 1 then
          -- Windows: use CMake
          return "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release " ..
              "&& cmake --build build --config Release " ..
              "&& cmake --install build --prefix build"
        else
          -- macOS / Linux: use Make
          return "make"
        end
      end)(),
    }
  },
  config = function()
    require("telescope").setup({
      defaults = {
        preview = {
          filesize_limit = 0.1, -- MB
          timeout = 250,        -- ms
        },
        layout_strategy = 'flex',
        layout_config = {
          horizontal = {
            preview_width = 0.6,
          },
          vertical = {
            mirror = false,
            preview_height = 0.4,
          },
          flex = {
            flip_columns = 90, -- Switch to vertical when width < 90 columns
          },
          width = 0.87,
          height = 0.80,
          preview_cutoff = 60, -- Show preview when window > 60 columns
        },
        mappings = {
          i = {
            ["<C-j>"] = "move_selection_next",
            ["<C-k>"] = "move_selection_previous",
            ["<CR>"] = "select_default",
            ["<C-u>"] = "preview_scrolling_up",
            ["<C-d>"] = "preview_scrolling_down",
          },
          n = {
            ["<C-j>"] = "move_selection_next",
            ["<C-k>"] = "move_selection_previous",
            ["<CR>"] = "select_default",
            ["<C-u>"] = "preview_scrolling_up",
            ["<C-d>"] = "preview_scrolling_down",
          },
        },
      },
      extensions = {
        fzf = {}
      },
      pickers = {
        live_grep = {
          -- Uses default center popup style
        },
        grep_string = {
          -- Uses default center popup style
        },
        find_files = {
          -- Uses default center popup style
        },
        lsp_references = {
          layout_strategy = 'flex',
          layout_config = {
            horizontal = {
              preview_width = 0.5,
            },
            vertical = {
              preview_height = 0.4,
              mirror = true,
            },
            flex = {
              flip_columns = 100, -- Switch to vertical when width < 100 columns
            },
            width = 0.9,
            height = 0.85,
          },
        },
        lsp_definitions = {
          layout_strategy = 'flex',
          layout_config = {
            horizontal = {
              preview_width = 0.5,
            },
            vertical = {
              preview_height = 0.4,
              mirror = true,
            },
            flex = {
              flip_columns = 100,
            },
            width = 0.9,
            height = 0.85,
          },
        },
        lsp_implementations = {
          layout_strategy = 'flex',
          layout_config = {
            horizontal = {
              preview_width = 0.5,
            },
            vertical = {
              preview_height = 0.4,
              mirror = true,
            },
            flex = {
              flip_columns = 100,
            },
            width = 0.9,
            height = 0.85,
          },
        },
        lsp_type_definitions = {
          layout_strategy = 'flex',
          layout_config = {
            horizontal = {
              preview_width = 0.5,
            },
            vertical = {
              preview_height = 0.4,
              mirror = true,
            },
            flex = {
              flip_columns = 100,
            },
            width = 0.9,
            height = 0.85,
          },
        },
        lsp_document_symbols = {
          layout_strategy = 'flex',
          layout_config = {
            horizontal = {
              preview_width = 0.5,
            },
            vertical = {
              preview_height = 0.4,
            },
            flex = {
              flip_columns = 100,
            },
            width = 0.9,
            height = 0.85,
          },
        },
        lsp_workspace_symbols = {
          layout_strategy = 'flex',
          layout_config = {
            horizontal = {
              preview_width = 0.5,
            },
            vertical = {
              preview_height = 0.4,
            },
            flex = {
              flip_columns = 100,
            },
            width = 0.9,
            height = 0.85,
          },
        },
      },
    })

    require("telescope").load_extension("ui-select")
    require('telescope').load_extension('fzf')


    local builtin = require 'telescope.builtin'
    vim.keymap.set('n', '<leader>sg', builtin.live_grep)
    vim.keymap.set('n', '<leader>sf', builtin.find_files)
    vim.keymap.set('n', '<leader>sh', builtin.help_tags)
    vim.keymap.set('n', '<leader>sk', builtin.keymaps)
    vim.keymap.set('n', '<leader>sF', builtin.filetypes)
    vim.keymap.set('n', '<leader>sr', builtin.oldfiles, { desc = 'Recent files' })
    vim.keymap.set('n', '<leader>gs', builtin.git_status)
    vim.keymap.set('n', '<leader>gc', builtin.git_commits)
    vim.keymap.set('n', '<leader>gr', builtin.git_branches)
    vim.keymap.set('n', '<leader>gss', builtin.git_stash)

    vim.keymap.set('n', '<leader>egS', function()
      require('telescope.builtin').git_status({
        prompt_title = "Git Status - Changed Files",
        attach_mappings = function(_, map)
          -- Open side-by-side diff with <C-d>
          map('i', '<C-v>', function(prompt_bufnr)
            local selection = require('telescope.actions.state').get_selected_entry()
            require('telescope.actions').close(prompt_bufnr)
            vim.cmd('DiffviewOpen -- ' .. selection.value)
          end)

          -- Stage file with <C-a> (add)
          map('i', '<C-a>', function(prompt_bufnr)
            local selection = require('telescope.actions.state').get_selected_entry()
            require('telescope.actions').close(prompt_bufnr)
            vim.fn.system({ 'git', 'add', selection.value })
            vim.notify('Staged: ' .. selection.value, vim.log.levels.INFO)
          end)

          -- Unstage file with <C-u> (unstage)
          map('i', '<C-u>', function(prompt_bufnr)
            local selection = require('telescope.actions.state').get_selected_entry()
            require('telescope.actions').close(prompt_bufnr)
            vim.fn.system({ 'git', 'reset', selection.value })
            vim.notify('Unstaged: ' .. selection.value, vim.log.levels.INFO)
          end)

          -- Open file in new tab with <C-t>
          map('i', '<C-t>', function(prompt_bufnr)
            local selection = require('telescope.actions.state').get_selected_entry()
            require('telescope.actions').close(prompt_bufnr)
            vim.cmd('tabnew ' .. selection.value)
          end)

          return true
        end
      })
    end, { desc = 'Enhanced Git Status with Telescope' })


    vim.keymap.set('n', "<leader>sn", function()
      require('telescope.builtin').find_files {
        cwd = vim.fn.stdpath("config")
      }
    end
    )
    -- ============================================
    -- THEME SWITCHER WITH REAL-TIME PREVIEW
    -- ============================================

    -- Main theme switcher with live preview (like NvChad)
    vim.keymap.set('n', '<leader>th', function()
      builtin.colorscheme({
        enable_preview = true, -- This enables real-time preview as you navigate!
      })
    end, { desc = '[T]heme selector with live preview' })

    -- Quick theme cycling through your favorites
    local favorite_themes = {
      'everforest',
      'gruvbox',
      'tokyonight',
      'tokyonight-night',
      'tokyonight-storm',
      'tokyonight-day',
      'tokyonight-moon',
      'github_dark',
      'github_dark_default',
      'github_dark_dimmed',
      'github_light',
      'github_light_default',
      'rose-pine',
      'catppuccin',
    }

    local current_theme_index = 1

    -- Cycle to next theme with notification
    vim.keymap.set('n', '<leader>tn', function()
      current_theme_index = current_theme_index % #favorite_themes + 1
      local theme = favorite_themes[current_theme_index]
      vim.cmd.colorscheme(theme)
      vim.notify('Theme: ' .. theme, vim.log.levels.INFO)
    end, { desc = 'Cycle to [N]ext theme' })

    -- Show only favorite themes
    vim.keymap.set('n', '<leader>tf', function()
      builtin.colorscheme({
        enable_preview = true,
        -- Filter to show only your installed/favorite themes
        -- This function will be called for each available colorscheme
        filter = function(colorscheme_name)
          for _, theme in ipairs(favorite_themes) do
            if colorscheme_name == theme then
              return true
            end
          end
          return false
        end,
      })
    end, { desc = '[T]heme selector ([F]avorites only)' })

    -- Optional: Save theme selection persistently
    local function save_theme_selection(theme_name)
      local config_dir = vim.fn.stdpath('config')
      local theme_file = config_dir .. '/lua/selected-theme.lua'
      local file = io.open(theme_file, 'w')
      if file then
        file:write(string.format("-- Auto-generated theme selection\nvim.cmd.colorscheme('%s')\n", theme_name))
        file:close()
      end
    end

    -- Auto-save theme when changed
    vim.api.nvim_create_autocmd('ColorScheme', {
      pattern = '*',
      callback = function(args)
        -- Uncomment the next line if you want to persist theme selection
        save_theme_selection(args.match)
      end,
    })
  end
}
