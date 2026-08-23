local plugins = {
  require('plugins.colorschemes'),
  require('plugins.treesitter'),
  require('plugins.file-explorer'),
  require('plugins.telescope'),
  require('plugins.lsp'),
  require('plugins.blink'),
  require('plugins.conform'),
  require('plugins.autopairs'),
  require('plugins.trouble'),
  require('plugins.misc'),
  require('plugins.lualine'),
  require('plugins.which-key'),
  require('plugins.mini-indentscope'),
  require('plugins.git'),
  require('plugins.crates'),
  require('plugins.rustaceanvim'),
  require('plugins.claudecode'),
  require('plugins.dap'),
  require('plugins.surround'),
  require('plugins.persistence'),
  require('plugins.diffview'),
  require('plugins.neogit'),
  require('plugins.python'),
  require('plugins.terminal'),
  require('plugins.neotest'),
  require('plugins.markdown'),
  require('plugins.navigation'),
}

local opts = {
  -- No plugin here needs a luarock. Leaving this on makes lazy bootstrap
  -- hererocks + luarocks the moment a plugin ships a rockspec (e.g. image.nvim).
  rocks = { enabled = false },
  ui = {
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    --icons =  {
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  }
}
require("lazy").setup(plugins, opts);
