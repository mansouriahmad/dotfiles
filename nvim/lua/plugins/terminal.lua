local platform = require('platform')

return {
  'akinsho/toggleterm.nvim',
  version = '*',
  keys = {
    { '<leader>tt', desc = 'Toggle terminal' },
    { '<leader>tr', desc = 'Run file' },
  },
  config = function()
    require('toggleterm').setup({
      size = function(term)
        if term.direction == 'horizontal' then
          return 15
        elseif term.direction == 'vertical' then
          return vim.o.columns * 0.4
        end
      end,
      open_mapping = [[<leader>tt]],
      direction = 'float',
      float_opts = {
        border = 'rounded',
        width = math.floor(vim.o.columns * 0.85),
        height = math.floor(vim.o.lines * 0.8),
      },
      shade_terminals = true,
      persist_mode = true,
      close_on_exit = true,
    })

    local Terminal = require('toggleterm.terminal').Terminal

    -- Run current file based on filetype
    vim.keymap.set('n', '<leader>tr', function()
      local ft = vim.bo.filetype
      local file = vim.fn.expand('%:p')
      -- macOS ships no bare `python`; an active venv/conda env puts both on PATH
      local py = platform.python()
      local cmd = ({
        python   = py .. ' ' .. file,
        rust     = 'cargo run',
        lua      = 'lua ' .. file,
        sh       = 'bash ' .. file,
        javascript = 'node ' .. file,
        typescript = 'npx ts-node ' .. file,
      })[ft]

      if cmd then
        Terminal:new({ cmd = cmd, direction = 'horizontal', close_on_exit = false }):toggle()
      else
        vim.notify('No run command for filetype: ' .. ft, vim.log.levels.WARN)
      end
    end, { desc = 'Run current file' })

    -- ESC exits terminal insert mode
    vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]], { desc = 'Exit terminal mode' })
  end,
}
