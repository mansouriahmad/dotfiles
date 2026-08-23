return {
  {
    "mrcjkb/rustaceanvim",
    version = "^5",
    lazy = false, -- Plugin is already lazy-loaded for Rust files
    init = function()
      vim.g.rustaceanvim = {
        -- Plugin configuration
        tools = {
          hover_actions = {
            auto_focus = true,
          },
        },
        -- LSP configuration
        server = {
          default_settings = {
            ["rust-analyzer"] = {
              cargo = {
                allFeatures = true,
              },
              check = {
                command = "clippy",
              },
              procMacro = {
                enable = true,
              },
            },
          },
        },
      }
    end,
  },
}
