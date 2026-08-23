return {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  config = function()
    local autopairs = require("nvim-autopairs")

    autopairs.setup({
      check_ts = true,      -- Enable treesitter integration
      ts_config = {
        lua = { "string" }, -- Don't add pairs in lua string treesitter nodes
        javascript = { "string", "template_string" },
        java = false,       -- Don't check treesitter on java
      },
      disable_filetype = { "TelescopePrompt", "spectre_panel" },
      disable_in_macro = true,        -- Disable when recording or executing a macro
      disable_in_visualblock = false, -- Disable when in visual block mode
      disable_in_replace_mode = true,
      ignored_next_char = [=[[%w%%%'%[%"%.%`%$]]=],
      enable_moveright = true,
      enable_afterquote = true,         -- Add bracket pairs after quote
      enable_check_bracket_line = true, -- Check bracket in same line
      enable_bracket_in_quote = true,
      enable_abbr = false,              -- Trigger abbreviation
      break_undo = true,                -- Switch for basic rule break undo sequence
      check_comma = true,
      map_cr = true,
      map_bs = true,   -- Map the <BS> key
      map_c_h = false, -- Map the <C-h> key to delete a pair
      map_c_w = false, -- Map <c-w> to delete a pair if possible
    })

    -- Rust-specific rules
    local Rule = require("nvim-autopairs.rule")
    local cond = require("nvim-autopairs.conds")

    -- Add custom rules for Rust
    autopairs.add_rules({
      -- Rust lifetime parameters: '<'a>
      Rule("<", ">", "rust")
          :with_pair(cond.before_regex("%w+"))
          :with_move(cond.after_regex(">")),

      -- Rust closure parameters: |param|
      Rule("|", "|", "rust")
          :with_pair(cond.not_after_regex("||"))
          :with_move(cond.after_regex("|")),
    })

    -- Integration with blink.cmp
    local blink_cmp = require("blink.cmp")
    if blink_cmp then
      -- Set up the integration
      autopairs.setup({
        map_cr = false, -- We'll handle this manually for blink integration
      })

      -- Custom CR mapping for blink.cmp integration
      vim.keymap.set("i", "<CR>", function()
        if blink_cmp.is_visible() then
          return blink_cmp.accept()
        else
          return autopairs.autopairs_cr()
        end
      end, { expr = true, replace_keycodes = false })
    end
  end,
}
