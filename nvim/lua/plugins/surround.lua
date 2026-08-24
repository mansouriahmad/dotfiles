return {
  "kylechui/nvim-surround",
  version = "^3",
  event = "VeryLazy",
  config = function()
    require("nvim-surround").setup()

    -- Surround the word under the cursor, then type the delimiter: gs"  gs(  gs`
    -- `g` is a pure prefix, so this fires the moment `s` lands and then waits
    -- indefinitely for the closing char -- no timeoutlen race like `ysiw"`.
    vim.keymap.set('n', 'gs', '<Plug>(nvim-surround-normal)iw', { desc = 'Surround word' })
    vim.keymap.set('n', 'gS', '<Plug>(nvim-surround-normal)iW', { desc = 'Surround WORD' })
  end,
}
