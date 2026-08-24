vim.g.have_nerd_fonts = true
-- Use the conda nvim-tools env if available, otherwise fall back to system python
local platform = require('platform')
local conda_root = vim.env.CONDA_ROOT or ((vim.env.DATA_ROOT or '/data') .. '/miniconda3')
local conda_python = platform.venv_python(conda_root .. '/envs/nvim-tools')
if vim.fn.executable(conda_python) == 1 then
  vim.g.python3_host_prog = conda_python
else
  vim.g.python3_host_prog = vim.fn.exepath(platform.python())
end
vim.opt.foldenable = false
vim.opt.foldmethod = 'manual'
vim.opt.foldlevelstart = 99

vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" },
  {
    command = "checktime",
  })


vim.opt.wildmode =
'list:longest' --" Decent wildmenui in completion, when there is more than one match, list all matches, and only complete to longest common match


vim.opt.vb = true -- never ever make my terminal beep

-- :help options
vim.opt.backup = false                          -- creates a backup file
vim.opt.clipboard = "unnamedplus"               -- allows neovim to access the system clipboard

-- Remote clipboard: when editing over SSH (headless VM has no X/Wayland display),
-- route yanks/pastes through OSC 52 so they reach the *local* machine's clipboard
-- via the terminal (works through Zellij + your SSH client). Only active over SSH.
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
  local ok, osc52 = pcall(require, 'vim.ui.clipboard.osc52')
  if ok then
    vim.g.clipboard = {
      name = 'OSC 52',
      copy = { ['+'] = osc52.copy('+'), ['*'] = osc52.copy('*') },
      paste = { ['+'] = osc52.paste('+'), ['*'] = osc52.paste('*') },
    }
  end
elseif vim.env.WAYLAND_DISPLAY and vim.fn.executable('wl-paste') == 1 then
  -- Local Wayland clipboard, but time-boxed. GNOME/mutter exposes no
  -- data-control protocol, so wl-clipboard must create a surface and wait for
  -- keyboard focus before the compositor hands over the selection. While the
  -- screen is locked that focus never arrives and wl-paste blocks forever --
  -- and since clipboard reads are synchronous, that freezes the whole editor.
  -- The timeout turns "frozen nvim" into "empty paste".
  -- cache_enabled routes copy through jobstart (async, and it keeps wl-copy
  -- alive to own the selection), so only the paste side can ever block.
  vim.g.clipboard = {
    name = 'wl-clipboard (timeout)',
    copy = {
      ['+'] = { 'wl-copy', '--type', 'text/plain' },
      ['*'] = { 'wl-copy', '--primary', '--type', 'text/plain' },
    },
    paste = {
      ['+'] = { 'timeout', '1', 'wl-paste', '--no-newline' },
      ['*'] = { 'timeout', '1', 'wl-paste', '--no-newline', '--primary' },
    },
    cache_enabled = 1,
  }
end
vim.opt.cmdheight = 2                           -- more space in the neovim command line for displaying messages
vim.opt.completeopt = { "menuone", "noselect" } -- mostly just for cmp
vim.opt.conceallevel = 0                        -- so that `` is visible in markdown files
vim.opt.fileencoding = "utf-8"                  -- the encoding written to a file
vim.opt.hlsearch = true                         -- highlight all matches on previous search pattern
vim.opt.ignorecase = true                       -- ignore case in search patterns
vim.opt.mouse = "a"                             -- allow the mouse to be used in neovim
vim.opt.pumheight = 10                          -- pop up menu height
vim.opt.showmode = false                        -- we don't need to see things like -- INSERT -- anymore
vim.opt.showtabline = 2                         -- always show tabs
vim.opt.smartcase = true                        -- smart case
vim.opt.smartindent = true                      -- make indenting smarter again
vim.opt.splitbelow = true                       -- force all horizontal splits to go below current window
vim.opt.splitright = true                       -- force all vertical splits to go to the right of current window
vim.opt.swapfile = false                        -- creates a swapfile
vim.opt.termguicolors = true                    -- set term gui colors (most terminals support this)
vim.opt.timeoutlen = 300                        -- time to wait for a mapped sequence to complete (in milliseconds)
vim.opt.undofile = true                         -- enable persistent undo
vim.opt.updatetime = 300                        -- faster completion (4000ms default)
vim.opt.writebackup = false                     -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
vim.opt.expandtab = true                        -- convert tabs to spaces
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2                          -- the number of spaces inserted for each indentation
vim.opt.tabstop = 2                             -- insert 2 spaces for a tab
vim.opt.cursorline = true                       -- highlight the current line
vim.opt.number = true                           -- set numbered lines
vim.opt.relativenumber = true                   -- set relative numbered lines
vim.opt.numberwidth = 4                         -- set number column width to 2 {default 4}
vim.opt.signcolumn =
"yes"                                           -- always show the sign column, otherwise it would shift the text each time
vim.opt.wrap = true                             -- display lines as one long line
vim.opt.scrolloff = 8                           -- is one of my fav
vim.opt.sidescrolloff = 8
vim.opt.guifont = "monospace:h17"               -- the font used in graphical neovim applications

-- Load per-project .nvim.lua config safely (only if file is trusted)
local local_config = vim.fn.getcwd() .. '/.nvim.lua'
if vim.fn.filereadable(local_config) == 1 then
  local ok, err = pcall(dofile, local_config)
  if not ok then
    vim.notify('Error in .nvim.lua: ' .. err, vim.log.levels.WARN)
  end
end
