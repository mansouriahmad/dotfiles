local platform = require('platform')

return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
    'nvim-neotest/neotest-python',
    'rouge8/neotest-rust',
  },
  keys = {
    { '<leader>nT', desc = 'Run all tests in file' },
    { '<leader>nt', desc = 'Run nearest test' },
    { '<leader>nl', desc = 'Run last test' },
    { '<leader>ns', desc = 'Toggle test summary' },
    { '<leader>no', desc = 'Toggle test output' },
    { '<leader>nS', desc = 'Stop tests' },
    { ']t',        desc = 'Next failed test' },
    { '[t',        desc = 'Prev failed test' },
  },
  config = function()
    require('neotest').setup({
      adapters = {
        require('neotest-python')({
          dap = { justMyCode = false },
          runner = 'pytest',
          python = function()
            -- Use active venv if available, otherwise fall back
            local venv = os.getenv('VIRTUAL_ENV') or os.getenv('CONDA_PREFIX')
            if venv then
              return platform.venv_python(venv)
            end
            return vim.fn.exepath(platform.python())
          end,
        }),
        require('neotest-rust')({
          args = { '--no-capture' },
          dap_adapter = 'lldb',
        }),
      },
      output = {
        open_on_run = 'short', -- auto-open output for failures
      },
      summary = {
        open = 'botright vsplit | vertical resize 40',
      },
      icons = {
        passed  = '',
        failed  = '',
        running = '',
        skipped = '',
        unknown = '',
      },
    })

    local nt = require('neotest')
    vim.keymap.set('n', '<leader>nt', function() nt.run.run() end,                          { desc = 'Run nearest test' })
    vim.keymap.set('n', '<leader>nT', function() nt.run.run(vim.fn.expand('%')) end,        { desc = 'Run all tests in file' })
    vim.keymap.set('n', '<leader>nl', function() nt.run.run_last() end,                     { desc = 'Run last test' })
    vim.keymap.set('n', '<leader>ns', function() nt.summary.toggle() end,                   { desc = 'Toggle test summary' })
    vim.keymap.set('n', '<leader>no', function() nt.output_panel.toggle() end,              { desc = 'Toggle test output' })
    vim.keymap.set('n', '<leader>nS', function() nt.run.stop() end,                         { desc = 'Stop tests' })
    vim.keymap.set('n', ']t',         function() nt.jump.next({ status = 'failed' }) end,   { desc = 'Next failed test' })
    vim.keymap.set('n', '[t',         function() nt.jump.prev({ status = 'failed' }) end,   { desc = 'Prev failed test' })
  end,
}
