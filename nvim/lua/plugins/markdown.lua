return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
    },
    ft = { 'markdown' },
    keys = {
      { '<leader>um', desc = 'Toggle markdown rendering' },
    },
    init = function()
      -- Prose-friendly wrapping in markdown buffers
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'markdown',
        callback = function()
          vim.opt_local.wrap = true
          vim.opt_local.linebreak = true
          vim.opt_local.breakindent = true
        end,
      })
    end,
    opts = {
      -- Render everywhere except insert/visual, so editing shows the raw text
      render_modes = { 'n', 'c', 't' },
      -- Reveal the raw line under the cursor while the rest stays rendered
      anti_conceal = { enabled = true },

      heading = {
        sign = false,
        icons = { '󰎤 ', '󰎧 ', '󰎪 ', '󰎭 ', '󰎱 ', '󰎳 ' },
        width = 'block',
        right_pad = 2,
      },

      code = {
        sign = false,
        width = 'block',
        border = 'thick',
        right_pad = 2,
        language_pad = 2,
      },

      bullet = {
        icons = { '●', '○', '◆', '◇' },
      },

      checkbox = {
        unchecked = { icon = '󰄱 ' },
        checked = { icon = '󰱒 ' },
        custom = {
          todo = { raw = '[-]', rendered = '󰥔 ', highlight = 'RenderMarkdownTodo' },
        },
      },

      pipe_table = {
        preset = 'round',
      },

      -- Requires the `latex2text` binary; enable if you install pylatexenc
      latex = { enabled = false },

      completions = {
        blink = { enabled = true },
      },
    },
    config = function(_, opts)
      require('render-markdown').setup(opts)

      vim.keymap.set('n', '<leader>um', function()
        require('render-markdown').toggle()
      end, { desc = 'Toggle markdown rendering' })
    end,
  },

  -- Inline images in the terminal. WezTerm speaks the kitty graphics protocol,
  -- but zellij (0.44) drops the escape sequences and offers no passthrough
  -- option, so images only appear in a plain WezTerm tab, not inside zellij.
  {
    '3rd/image.nvim',
    ft = { 'markdown' },
    -- No terminal on Windows speaks the kitty graphics protocol, and the
    -- magick_cli processor needs an ImageMagick CLI on PATH. Skip it there
    -- rather than let it error on every markdown buffer.
    cond = not require('platform').is_windows,
    -- Skip lazy's luarocks/hererocks build: the `magick` rock is unnecessary
    -- because we use the `magick_cli` processor below
    build = false,
    keys = {
      { '<leader>ui', desc = 'Toggle inline images' },
    },
    opts = {
      backend = 'kitty',
      -- Avoids the `magick` luarock; shells out to the ImageMagick 7 CLI instead
      processor = 'magick_cli',
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = true,
          -- Draw every image inline where its link sits. The cursor-only mode
          -- defaults to a floating popup, which nvim 0.11 rejects because
          -- image.nvim computes a fractional window width for it.
          only_render_image_at_cursor = false,
          only_render_image_at_cursor_mode = 'inline',
          filetypes = { 'markdown' },
        },
      },
      max_width_window_percentage = 60,
      max_height_window_percentage = 40,
      window_overlap_clear_enabled = true,
      window_overlap_clear_ft_ignore = { 'cmp_menu', 'cmp_docs', 'blink-cmp-menu', 'blink-cmp-documentation', '' },
      editor_only_render_when_focused = true,
    },
    config = function(_, opts)
      require('image').setup(opts)

      vim.keymap.set('n', '<leader>ui', function()
        local image = require('image')
        if image.is_enabled() then
          image.disable()
        else
          image.enable()
        end
      end, { desc = 'Toggle inline images' })
    end,
  },

  -- Callout / checkbox completions inside markdown
  {
    'saghen/blink.cmp',
    optional = true,
    opts = {
      sources = {
        default = { 'markdown' },
        providers = {
          markdown = {
            name = 'RenderMarkdown',
            module = 'render-markdown.integ.blink',
            score_offset = 100,
          },
        },
      },
    },
  },
}
