local function gitBlame()
  local gitsigns = require("gitsigns")

  -- if a "gitsigns-blame://..." window is open, close it
  local wins = vim.api.nvim_list_wins()
  for _, win in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(win)
    local name = vim.api.nvim_buf_get_name(buf)
    print("name: ", name)
    if name:match("^gitsigns%-blame://") then
      vim.api.nvim_win_close(win, true)
      return
    end
    print("no match")
  end

  gitsigns.blame()
end

local function gitDiff()
  local gitsigns = require("gitsigns")

  -- if a "gitsigns://..." window is open, close it
  local wins = vim.api.nvim_list_wins()
  for _, win in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(win)
    local name = vim.api.nvim_buf_get_name(buf)
    if name:match("^gitsigns://") then
      vim.api.nvim_win_close(win, true)
      return
    end
  end

  gitsigns.diffthis()
end

return {
  -- TODO: move signs to stats col
  "lewis6991/gitsigns.nvim",
  pin = true,
  event = "VeryLazy",
  opts = {
    word_diff = false,
    on_attach = function(bufnr)
      local gitsigns = require("gitsigns")

      local function map(mode, l, r, desc)
        vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
      end

      -- Navigation
      map("n", "]g", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]g", bang = true })
        else
          gitsigns.nav_hunk("next")
        end
      end, "next git change")

      map("n", "[g", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[g", bang = true })
        else
          gitsigns.nav_hunk("prev")
        end
      end, "prev git change")

      -- diff
      map("n", "<leader>gd", gitDiff, "Git Diff")
      map("n", "<leader>gw", gitsigns.toggle_word_diff, "Git diff toggle")

      -- Text object
      map({ "o", "x" }, "ig", gitsigns.select_hunk)

      -- Stage/Unstage hunks
      map("n", "<leader>ga", gitsigns.stage_hunk, "Git Add")
      map("n", "<leader>gr", gitsigns.reset_hunk, "Git Reset")
      map("v", "<leader>ga", function()
        gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, "Git Add")
      map("v", "<leader>gr", function()
        gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, "Git Reset")
      map("n", "<leader>gA", gitsigns.stage_buffer, "Git Add Buffer")
      map("n", "<leader>gR", gitsigns.reset_buffer, "Git Reset Buffer")

      -- preview
      map("n", "<leader>gp", gitsigns.preview_hunk, "Git Preview")
      map("n", "<leader>gi", gitsigns.preview_hunk_inline, "Git Preview Inline")

      -- quickfix
      map("n", "<leader>gq", function()
        gitsigns.setqflist("all")
      end, "Git Quickfix")
    end,
  },
  keys = {
    {
      "<leader>gb",
      gitBlame,
      desc = "Git Blame",
    },
    {
      "<leader>gd",
      gitDiff,
      desc = "Git Diff",
    },
  },
}
