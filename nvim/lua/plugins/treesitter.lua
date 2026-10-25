-- nvim-treesitter `main` branch (Neovim 0.12+). Needs the tree-sitter CLI and a C compiler.
-- Unlike the old `master` branch, it only installs parsers; highlighting is started below.

local ensure_installed = {
  "c", "cpp", "cmake", "make", "lua", "vim", "vimdoc", "query",
  "markdown", "markdown_inline", "rust", "python", "yaml",
}

local max_filesize = 100 * 1024 -- skip treesitter on files over 100 KB

local function too_big(buf)
  local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
  return ok and stats and stats.size > max_filesize
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")
      ts.install(ensure_installed)

      local available = {}
      for _, lang in ipairs(ts.get_available()) do
        available[lang] = true
      end

      local function start(buf, lang)
        if not vim.api.nvim_buf_is_valid(buf) or not pcall(vim.treesitter.start, buf, lang) then
          return
        end
        if vim.treesitter.query.get(lang, "indents") then
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user-treesitter", { clear = true }),
        callback = function(args)
          local buf = args.buf
          local lang = vim.treesitter.language.get_lang(args.match)
          if not lang or too_big(buf) then
            return
          end
          if vim.list_contains(ts.get_installed(), lang) then
            start(buf, lang)
          elseif available[lang] then
            -- auto_install replacement: install the parser, then start it
            ts.install({ lang }):await(function()
              vim.schedule(function() start(buf, lang) end)
            end)
          end
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = "nvim-treesitter/nvim-treesitter",
    event = "BufReadPost",
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = { lookahead = true },
        move = { set_jumps = true },
      })

      local select = require("nvim-treesitter-textobjects.select")
      local move = require("nvim-treesitter-textobjects.move")
      local swap = require("nvim-treesitter-textobjects.swap")

      local selects = {
        af = { "@function.outer", "Select around function" },
        ["if"] = { "@function.inner", "Select inside function" },
        ac = { "@class.outer", "Select around class" },
        ic = { "@class.inner", "Select inside class" },
        aa = { "@parameter.outer", "Select around parameter" },
        ia = { "@parameter.inner", "Select inside parameter" },
        al = { "@loop.outer", "Select around loop" },
        il = { "@loop.inner", "Select inside loop" },
        ai = { "@conditional.outer", "Select around conditional" },
        ii = { "@conditional.inner", "Select inside conditional" },
      }
      for lhs, spec in pairs(selects) do
        vim.keymap.set({ "x", "o" }, lhs, function()
          select.select_textobject(spec[1], "textobjects")
        end, { desc = spec[2] })
      end

      local moves = {
        goto_next_start = {
          ["]f"] = { "@function.outer", "Next function start" },
          ["]c"] = { "@class.outer", "Next class start" },
          ["]a"] = { "@parameter.inner", "Next parameter" },
        },
        goto_next_end = {
          ["]F"] = { "@function.outer", "Next function end" },
          ["]C"] = { "@class.outer", "Next class end" },
        },
        goto_previous_start = {
          ["[f"] = { "@function.outer", "Previous function start" },
          ["[c"] = { "@class.outer", "Previous class start" },
          ["[a"] = { "@parameter.inner", "Previous parameter" },
        },
        goto_previous_end = {
          ["[F"] = { "@function.outer", "Previous function end" },
          ["[C"] = { "@class.outer", "Previous class end" },
        },
      }
      for fn, maps in pairs(moves) do
        for lhs, spec in pairs(maps) do
          vim.keymap.set({ "n", "x", "o" }, lhs, function()
            move[fn](spec[1], "textobjects")
          end, { desc = spec[2] })
        end
      end

      vim.keymap.set("n", "<leader>sp", function()
        swap.swap_next("@parameter.inner")
      end, { desc = "Swap with next parameter" })
      vim.keymap.set("n", "<leader>sP", function()
        swap.swap_previous("@parameter.inner")
      end, { desc = "Swap with previous parameter" })
    end,
  },
}
