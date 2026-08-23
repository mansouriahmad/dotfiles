return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles" },
  keys = {
    { "<leader>gdo", "<cmd>DiffviewOpen<cr>", desc = "Diff View Open" },
    { "<leader>gdH", "<cmd>DiffviewFileHistory %<cr>", desc = "File History (Diffview)" },
    { "<leader>gdC", "<cmd>DiffviewClose<cr>", desc = "Close Diff View" },
    { "<leader>gdR", "<cmd>DiffviewFileHistory<cr>", desc = "Repo History (Diffview)" },
  },
  opts = {
    enhanced_diff_hl = true,
    hooks = {
      -- View-only diffs: make the git-revision/index buffers non-editable so an
      -- accidental edit + :w on the left pane can't trigger the stage_index_file
      -- path (the "E19: Mark has invalid line number" error). These buffers have
      -- a non-empty buftype (nofile/acwrite); the real working-tree file has
      -- buftype="" and stays editable, so normal edits and merge-conflict
      -- resolution still work.
      diff_buf_read = function(bufnr)
        if vim.bo[bufnr].buftype ~= "" then
          vim.bo[bufnr].modifiable = false
          vim.bo[bufnr].readonly = true
        end
      end,
    },
    view = {
      default = { layout = "diff2_horizontal" },
      merge_tool = { layout = "diff3_horizontal" },
      file_history = { layout = "diff2_horizontal" },
    },
    file_panel = {
      listing_style = "tree",
      win_config = { position = "left", width = 35 },
    },
  },
}
