return {
  {
    "williamboman/mason.nvim",
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "neovim/nvim-lspconfig",
      "artemave/workspace-diagnostics.nvim",
    },
    opts = {
      servers = {
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = {
                globals = { "vim" },
              },
            },
          },
        },
        ruff = {
          init_options = {
            settings = {
              -- Any extra CLI arguments for `ruff` go here.
              args = {},
            }
          }
        },
        omnisharp = {
          settings = {
            FormattingOptions = {
              -- Enables support for reading code style, naming convention and analyzer
              -- settings from .editorconfig.
              EnableEditorConfigSupport = true,
              -- Specifies whether 'using' directives should be grouped and sorted during
              -- document formatting.
              OrganizeImports = true,
            },
            MsBuild = {
              -- If true, MSBuild project system will only load projects for files that
              -- were opened in the editor. This setting is useful for big C# codebases
              -- and allows for faster initialization of code navigation features only
              -- for projects that are relevant to code that is being edited.
              LoadProjectsOnDemand = false,
            },
            -- Enable auto-import suggestions
            EnableImportCompletion = true,
            -- Enable code actions for adding using statements
            EnableRoslynAnalyzers = true,
            -- Enable semantic highlighting
            EnableSemanticHighlighting = true,
          },
        },
        pyright = {
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "basic",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
              },
            },
          },
        },
        taplo = {},
        bashls = {},
        yamlls = {},
        dockerls = {},
        marksman = {},
      },
    },
    config = function(_, opts)
      require("mason").setup()

      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "rust_analyzer", "ruff", "omnisharp", "pyright", "taplo", "bashls", "yamlls", "dockerls", "marksman" },
        automatic_installation = true,
        -- rust_analyzer is managed by rustaceanvim — don't let mason-lspconfig start it
        automatic_enable = {
          exclude = { "rust_analyzer" },
        },
      })

      -- OS-agnostic and .NET-version-agnostic OmniSharp binary lookup.  Mason
      -- packages OmniSharp in a cross-platform way, but the executable name and
      -- whether we run the shell script or the .exe differs by OS.  Fall back to
      -- whatever is on $PATH if Mason hasn’t installed it yet.
      local function get_omnisharp_cmd()
        local base = vim.fn.stdpath("data") .. "/mason/packages/omnisharp"
        local exe = "OmniSharp"
        if vim.fn.has("win32") == 1 then
          exe = "OmniSharp.exe"
        end
        local candidate = base .. "/" .. exe
        if vim.fn.executable(candidate) == 1 then
          return { candidate, "--languageserver", "--hostPID", tostring(vim.fn.getpid()) }
        end
        -- Fallback to whatever the user has in PATH (may be managed externally).
        return { "omnisharp", "--languageserver", "--hostPID", tostring(vim.fn.getpid()) }
      end

      -- ensure there is an entry to modify; nil value means default settings
      opts.servers.omnisharp = opts.servers.omnisharp or {}
      opts.servers.omnisharp.cmd = get_omnisharp_cmd()

      for server, config in pairs(opts.servers) do
        vim.lsp.config(server, config)
        vim.lsp.enable(server)
      end

      -- Virtual lines toggle state
      local virtual_lines_enabled = false

      -- Function to toggle virtual lines
      local function toggle_virtual_lines()
        virtual_lines_enabled = not virtual_lines_enabled
        vim.diagnostic.config({
          virtual_lines = virtual_lines_enabled,
        })
      end

      -- All diagnostics toggle state (enabled by default)
      local diagnostics_enabled = true

      -- Function to toggle all diagnostics (virtual text, underline, signs, virtual lines)
      local function toggle_all_diagnostics()
        diagnostics_enabled = not diagnostics_enabled
        if diagnostics_enabled then
          -- Re-enable all diagnostics, restore virtual_lines to its previous state
          vim.diagnostic.config({
            virtual_text = true,
            underline = true,
            signs = true,
            virtual_lines = virtual_lines_enabled,
          })
          vim.notify("Diagnostics enabled", vim.log.levels.INFO)
        else
          -- Disable all diagnostics
          vim.diagnostic.config({
            virtual_text = false,
            underline = false,
            signs = false,
            virtual_lines = false,
          })
          vim.notify("Diagnostics disabled", vim.log.levels.INFO)
        end
      end

      vim.diagnostic.config({
        virtual_text = true,
        virtual_lines = virtual_lines_enabled,
        underline = true,
        signs = true,
      })

      -- Set up LSP keymaps using LspAttach autocommand (recommended approach)
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if client then
            require("workspace-diagnostics").setup({
              workspace_files = function()
                -- Cross-platform file finding
                if vim.fn.has('win32') == 1 then
                  -- Windows PowerShell command
                  return vim.fn.systemlist(
                    'powershell -Command "Get-ChildItem -Recurse -Include *.rs,*.lua,*.py,*.js,*.ts,*.tsx | Select-Object -First 1000 | ForEach-Object { $_.FullName }"'
                  )
                else
                  -- Unix/Linux/macOS command
                  return vim.fn.systemlist(
                    "find . -name '*.rs' -o -name '*.lua' -o -name '*.py' -o -name '*.js' -o -name '*.ts' -o -name '*.tsx' | head -1000"
                  )
                end
              end
            })
            -- Auto-populate workspace diagnostics when LSP attaches
            require("workspace-diagnostics").populate_workspace_diagnostics(client, ev.buf)
          end

          -- Navigation with Telescope (live preview)
          local telescope = require('telescope.builtin')
          vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { buffer = ev.buf, desc = 'Go to declaration' })
          vim.keymap.set("n", "gd", telescope.lsp_definitions, { buffer = ev.buf, desc = 'Go to definition' })
          vim.keymap.set("n", "gi", telescope.lsp_implementations, { buffer = ev.buf, desc = 'Go to implementation' })
          vim.keymap.set("n", "<leader>D", telescope.lsp_type_definitions,
            { buffer = ev.buf, desc = 'Go to type definition' })
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = ev.buf, desc = 'Rename buffer' })
          vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { buffer = ev.buf, desc = 'Code actions' })

          -- C# specific: Fix using statements (auto-import)
          if client.name == "omnisharp" then
            vim.keymap.set("n", "<leader>fu", function()
              vim.lsp.buf.code_action({
                context = { only = { "source.organizeImports" } },
                apply = true,
              })
            end, { buffer = ev.buf, desc = 'Fix using statements (auto-import)' })
          end
          -- Faster references: disable previewer and skip declarations
          vim.keymap.set("n", "gr", function()
            telescope.lsp_references({
              previewer = false,            -- avoid heavy preview rendering
              include_declarations = false, -- often not needed and slows down
              show_line = false,            -- lighter entries
              trim_text = true,
            })
          end, { buffer = ev.buf, desc = 'Go to references' })

          -- Additional LSP Telescope commands with live preview
          vim.keymap.set("n", "<leader>ls", telescope.lsp_document_symbols,
            { buffer = ev.buf, desc = 'Document symbols' })
          vim.keymap.set("n", "<leader>lw", telescope.lsp_workspace_symbols,
            { buffer = ev.buf, desc = 'Workspace symbols' })

          -- Documentation
          vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = ev.buf, desc = 'Hover Documentation' })
          vim.keymap.set("n", "<leader>f", function()
            vim.lsp.buf.format({ async = true })
          end, { buffer = ev.buf, desc = 'Format the source' })

          vim.keymap.set("n", "<leader>d", function()
            vim.diagnostic.open_float({
              border = "rounded",
            })
          end, { buffer = ev.buf, desc = 'Open float diagnostic' })

          -- Toggle virtual lines diagnostics
          vim.keymap.set("n", "<leader>vl", toggle_virtual_lines,
            { buffer = ev.buf, desc = 'Toggle virtual lines diagnostics' })
        end,
      })

      -- Global keymap for diagnostics toggle (works everywhere, even when LSP not attached)
      vim.keymap.set("n", "<leader>dt", toggle_all_diagnostics, { desc = 'Toggle all diagnostics' })
    end
  }
}
