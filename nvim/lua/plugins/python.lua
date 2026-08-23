return {
  {
    "linux-cultist/venv-selector.nvim",
    branch = "main",
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-telescope/telescope.nvim",
      "mfussenegger/nvim-dap-python",
    },
    cmd = "VenvSelect",
    ft = "python",
    keys = {
      { "<leader>pv", "<cmd>VenvSelect<cr>", desc = "Select Python Venv" },
      { "<leader>pV", "<cmd>VenvSelectCached<cr>", desc = "Show Cached Venv" },
    },
    -- venv-selector 'main' is the rewritten API: settings = { options, search }.
    -- Its built-in fd searches auto-discover .venv/venv/poetry/pyenv/conda/uv,
    -- so the old top-level name/search/anaconda_* keys are gone (passing
    -- search=true crashed finalize_settings with "expected table, got boolean").
    opts = {
      settings = {
        options = {
          notify_user_on_venv_activation = true,
        },
      },
    },
  },
}
