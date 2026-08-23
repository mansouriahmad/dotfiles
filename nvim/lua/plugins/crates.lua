return {
  {
    "saecki/crates.nvim",
    event = { "BufRead Cargo.toml" },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("crates").setup({
        lsp = {
          enabled = true,
          actions = true,
          completion = true,
          hover = true,
        },
      })

      local crates = require("crates")

      -- Only set keymaps for functions that exist
      if crates.upgrade_crate then
        vim.keymap.set("n", "<leader>cu", crates.upgrade_crate, { silent = true, desc = "Upgrade crate" })
      end
      if crates.upgrade_crates then
        vim.keymap.set("v", "<leader>cu", crates.upgrade_crates, { silent = true, desc = "Upgrade crates" })
      end
      if crates.show_versions_popup then
        vim.keymap.set("n", "<leader>cv", crates.show_versions_popup, { silent = true, desc = "Show versions" })
      end
      if crates.show_features_popup then
        vim.keymap.set("n", "<leader>cf", crates.show_features_popup, { silent = true, desc = "Show features" })
      end
      if crates.show_dependencies_popup then
        vim.keymap.set("n", "<leader>cd", crates.show_dependencies_popup, { silent = true, desc = "Show dependencies" })
      end
    end,
  }
}
