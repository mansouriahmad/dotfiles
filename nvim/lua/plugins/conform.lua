return {
  'stevearc/conform.nvim',
  opts = {},
  config = function()
    require("conform").setup({
      formatters_by_ft = {
        lua = { "stylua" },
        -- Shell formatting via shfmt
        sh = { "shfmt" },
        bash = { "shfmt" },
        -- Ruff handles both formatting and import sorting for Python
        python = { "ruff_format", "ruff_organize_imports" },
        -- You can customize some of the format options for the filetype (:help conform.format
        rust = { "rustfmt", lsp_format = "fallback" },
        -- CSharpier (opinionated, like prettier); falls back to OmniSharp if
        -- it isn't installed (:MasonInstall csharpier).
        cs = { "csharpier", lsp_format = "fallback" },
        -- C/C++ via clang-format (Mason). Reads a .clang-format file if the project has one.
        c = { "clang-format" },
        cpp = { "clang-format" },
        -- TOML formatting via taplo LSP
        toml = { "taplo" },
        -- Conform will run the first available formatter
        javascript = { "prettierd", "prettier", stop_after_first = true },
      },
      format_on_save = function(bufnr)
        -- CSharpier starts a .NET process, which can take over 500ms.
        local slow = vim.bo[bufnr].filetype == "cs"
        return { timeout_ms = slow and 3000 or 500, lsp_format = "fallback" }
      end,
    })
  end

}
