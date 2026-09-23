-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

local opts = { noremap = true, silent = true }


vim.keymap.set("n", "<Space>", "<Nop>", opts)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- vim.keymap.set('n', '<leader>e', '<cmd>NvimTreeToggle<CR>', { desc = 'Toggle NvimTree' })

-- Quick navigation shortcuts
vim.keymap.set('', 'H', '^')
vim.keymap.set('', 'L', '$')

-- FIXED: Consistent arrow key behavior - choose one approach
-- Option 1: Disable with educational messages (current)
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')
-- FIXED: Removed conflicting left/right mappings

-- Option 2: Allow arrow keys for buffer switching
vim.keymap.set('n', '<left>', ':bp<cr>', { desc = 'Previous buffer' })
vim.keymap.set('n', '<right>', ':bn<cr>', { desc = 'Next buffer' })

-- Window navigation (Ctrl-hjkl) lives in plugins/navigation.lua: smart-splits
-- makes it span Neovim windows and Zellij panes as one space.

-- FIXED: Consistent line movement in normal mode
vim.keymap.set("n", "<leader>j", ":m .+1<CR>==", { noremap = true, silent = true, desc = "Move line down" })
vim.keymap.set("n", "<leader>k", ":m .-2<CR>==", { noremap = true, silent = true, desc = "Move line up" })

-- FIXED: Consistent line movement in visual mode
vim.keymap.set("x", "<leader>j", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("x", "<leader>k", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Updates how vim uses registers when pasting
vim.keymap.set("v", "p", '"_dP', opts)

-- Mouse selection copies, like Zellij's copy_on_select.
-- Zellij only copies a drag it sees itself; while Neovim is focused mouse=a
-- hands every event to us instead, so the drag ends as a visual selection and
-- nothing reaches the clipboard. Yank it on button release: "+ is OSC 52 over
-- SSH (see options.lua), so it lands on the *local* machine's clipboard.
-- gv keeps the selection up afterwards so the drag still looks like a drag.
vim.keymap.set('x', '<LeftRelease>', '"+ygv', { desc = 'Copy mouse selection to clipboard' })

-- Less restrictive insert mode arrow keys (allow basic movement)
vim.keymap.set('i', '<up>', '<up>')
vim.keymap.set('i', '<down>', '<down>')
vim.keymap.set('i', '<left>', '<left>')
vim.keymap.set('i', '<right>', '<right>')

-- Make j and k move by visual line, not actual line, when text is soft-wrapped
vim.keymap.set('n', 'j', 'gj')
vim.keymap.set('n', 'k', 'gk')

-- Handy keymap for replacing up to next _ (like in variable names)
vim.keymap.set('n', '<leader>m', 'ct_', { desc = 'Delete until next _' })

-- F1 is pretty close to Esc, so you probably meant Esc
vim.keymap.set('', '<F1>', '<Esc>')
vim.keymap.set('i', '<F1>', '<Esc>')

-- Save all files
vim.keymap.set('n', '<leader>W', ':wa<CR>', { noremap = true, silent = true, desc = 'Save all files' })

-- More useful diffs (nvim -d) by ignoring whitespace
vim.opt.diffopt:append('iwhite')

-- Quick file finder (uses Telescope)
vim.keymap.set('n', '<C-p>', '<cmd>Telescope find_files<cr>', { desc = 'Find files' })

-- Show/hide hidden characters
vim.keymap.set('n', '<leader>,', ':set invlist<cr>', { desc = 'Toggle list mode' })

-- Navigate diagnostics
vim.keymap.set('n', ']e', function() vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR }) end, { desc = 'Next error' })
vim.keymap.set('n', '[e', function() vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR }) end, { desc = 'Prev error' })
vim.keymap.set('n', ']w', function() vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.WARN }) end,  { desc = 'Next warning' })
vim.keymap.set('n', '[w', function() vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.WARN }) end,  { desc = 'Prev warning' })

-- Always center search results
vim.keymap.set('n', 'n', 'nzz', { silent = true })
vim.keymap.set('n', 'N', 'Nzz', { silent = true })
vim.keymap.set('n', '*', '*zz', { silent = true })
vim.keymap.set('n', '#', '#zz', { silent = true })
vim.keymap.set('n', 'g*', 'g*zz', { silent = true })


-- in your init.lua or a lua config file
vim.keymap.set("i", "jk", "<Esc>", { noremap = true, silent = true })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- [[ Rust-specific keymaps ]]
-- Add println! statement for the variable under cursor
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'rust',
  callback = function()
    vim.keymap.set('n', '<leader>p', function()
      -- Get the current line and cursor position
      local current_line = vim.api.nvim_get_current_line()
      local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
      
      -- Find the word under cursor (variable name)
      local word_start = cursor_col + 1
      local word_end = cursor_col + 1
      
      -- Find start of word
      while word_start > 1 and string.match(current_line:sub(word_start - 1, word_start - 1), '[%w_]') do
        word_start = word_start - 1
      end
      
      -- Find end of word
      while word_end <= #current_line and string.match(current_line:sub(word_end, word_end), '[%w_]') do
        word_end = word_end + 1
      end
      
      -- Extract the variable name
      local variable_name = current_line:sub(word_start, word_end - 1)
      
      if variable_name and variable_name ~= '' then
        -- Rust keywords that should not be printed
        local rust_keywords = {
          'fn', 'let', 'mut', 'const', 'static', 'if', 'else', 'match', 'for', 'while', 'loop',
          'break', 'continue', 'return', 'struct', 'enum', 'impl', 'trait', 'mod', 'use',
          'pub', 'priv', 'crate', 'super', 'self', 'Self', 'as', 'where', 'type', 'async',
          'await', 'move', 'ref', 'dyn', 'unsafe', 'extern', 'static', 'const', 'in',
          'true', 'false', 'None', 'Some', 'Ok', 'Err', 'Result', 'Option', 'String',
          'Vec', 'HashMap', 'BTreeMap', 'Box', 'Rc', 'Arc', 'Mutex', 'RwLock'
        }
        
        -- Check if it's a keyword
        local is_keyword = false
        for _, keyword in ipairs(rust_keywords) do
          if variable_name == keyword then
            is_keyword = true
            break
          end
        end
        
        if is_keyword then
          vim.notify('Cannot print keyword: ' .. variable_name, vim.log.levels.WARN)
          return
        end
        
        -- Check if the variable is actually defined in the current scope
        -- Look for variable declarations in the current function/scope
        local current_line_num = vim.api.nvim_win_get_cursor(0)[1]
        local buffer_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        
        -- Search backwards from current line to find variable declarations
        local variable_found = false
        local brace_count = 0
        local in_function = false
        
        for i = current_line_num - 1, 1, -1 do
          local line = buffer_lines[i]
          
          -- Count braces to track scope
          for char in line:gmatch('.') do
            if char == '{' then
              brace_count = brace_count + 1
              in_function = true
            elseif char == '}' then
              brace_count = brace_count - 1
            end
          end
          
          -- Look for variable declarations (let, const, static, function parameters)
          if line:match('let%s+' .. variable_name .. '%s*=') or
             line:match('const%s+' .. variable_name .. '%s*=') or
             line:match('static%s+' .. variable_name .. '%s*=') or
             line:match('fn%s+[^(]*%(' .. variable_name .. '%s*:') or
             line:match('fn%s+[^(]*%(' .. variable_name .. '%s*,') or
             line:match('fn%s+[^(]*%(' .. variable_name .. '%s*%)') or
             line:match('for%s+' .. variable_name .. '%s+in') or
             line:match('match%s+.*%{|' .. variable_name .. '%s*=>') then
            variable_found = true
            break
          end
          
          -- If we've gone outside the current function scope, stop searching
          if in_function and brace_count <= 0 then
            break
          end
        end
        
        if not variable_found then
          vim.notify('Variable "' .. variable_name .. '" not found in current scope', vim.log.levels.WARN)
          return
        end
        
        -- Get current line number
        local current_line_num = vim.api.nvim_win_get_cursor(0)[1]
        
        -- Create the println statement
        local println_statement = string.format('    println!("%s: {:?}", %s);', variable_name, variable_name)
        
        -- Insert the println statement on the next line
        vim.api.nvim_buf_set_lines(0, current_line_num, current_line_num, false, { println_statement })
        
        -- Move cursor to the end of the inserted line
        vim.api.nvim_win_set_cursor(0, { current_line_num + 1, #println_statement })
      else
        vim.notify('No variable found under cursor', vim.log.levels.WARN)
      end
    end, { buffer = true, desc = 'Add println! for variable under cursor' })
  end,
})
