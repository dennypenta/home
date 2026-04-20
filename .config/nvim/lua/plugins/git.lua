local gitsource = require("pkg.gitsource")

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

local function gitDiffCommit()
  local wins = vim.api.nvim_list_wins()
  local gitdiff_wins = {}
  for _, win in ipairs(wins) do
    local name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
    if name:match("^gitdiff://") then
      table.insert(gitdiff_wins, win)
    end
  end

  if #gitdiff_wins > 0 then
    for _, win in ipairs(gitdiff_wins) do
      local buf = vim.api.nvim_win_get_buf(win)
      vim.api.nvim_win_close(win, true)
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    vim.cmd("diffoff")
    return
  end

  local commits = vim.fn.systemlist("git log --oneline -30")
  if vim.v.shell_error ~= 0 or #commits == 0 then
    vim.notify("No commits found", vim.log.levels.WARN)
    return
  end

  local rel_file = vim.fn.expand("%:.")
  local ft = vim.bo.filetype

  vim.ui.select(commits, { prompt = "Diff against commit:" }, function(choice)
    if not choice then return end
    local hash = choice:match("^(%S+)")

    local lines = vim.fn.systemlist("git show " .. hash .. ":" .. vim.fn.shellescape(rel_file) .. " 2>/dev/null")
    if vim.v.shell_error ~= 0 then
      vim.notify("Could not get file at " .. hash, vim.log.levels.WARN)
      return
    end

    local commit_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(commit_buf, "gitdiff://" .. hash)
    vim.api.nvim_buf_set_lines(commit_buf, 0, -1, false, lines)
    vim.bo[commit_buf].filetype = ft
    vim.bo[commit_buf].modifiable = false
    vim.bo[commit_buf].buftype = "nofile"

    local orig_win = vim.api.nvim_get_current_win()

    vim.cmd("leftabove vsplit")
    local left_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(left_win, commit_buf)
    vim.cmd("diffthis")

    vim.api.nvim_set_current_win(orig_win)
    vim.cmd("diffthis")
  end)
end

local _gitshow_orig_buf = nil

local function gitShowCommit()
  local wins = vim.api.nvim_list_wins()
  local gitshow_wins = {}
  for _, win in ipairs(wins) do
    local name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
    if name:match("^gitshow://") then
      table.insert(gitshow_wins, win)
    end
  end

  if #gitshow_wins > 0 then
    for _, win in ipairs(gitshow_wins) do
      local buf = vim.api.nvim_win_get_buf(win)
      local name = vim.api.nvim_buf_get_name(buf)
      if not name:match("%^$") and _gitshow_orig_buf and vim.api.nvim_buf_is_valid(_gitshow_orig_buf) then
        vim.api.nvim_win_set_buf(win, _gitshow_orig_buf)
        vim.api.nvim_win_call(win, function() vim.cmd("diffoff") end)
        vim.api.nvim_set_current_win(win)
        vim.api.nvim_buf_delete(buf, { force = true })
      else
        vim.api.nvim_win_close(win, true)
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
    _gitshow_orig_buf = nil
    return
  end

  local commits = vim.fn.systemlist("git log --oneline -30")
  if vim.v.shell_error ~= 0 or #commits == 0 then
    vim.notify("No commits found", vim.log.levels.WARN)
    return
  end

  local rel_file = vim.fn.expand("%:.")
  local ft = vim.bo.filetype

  vim.ui.select(commits, { prompt = "Show commit:" }, function(choice)
    if not choice then return end
    local hash = choice:match("^(%S+)")

    local function load_rev(rev)
      local lines = vim.fn.systemlist("git show " .. rev .. ":" .. vim.fn.shellescape(rel_file) .. " 2>/dev/null")
      return vim.v.shell_error == 0 and lines or {}
    end

    local before_lines = load_rev(hash .. "^")
    local after_lines = load_rev(hash)

    local function make_buf(name, lines)
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(buf, name)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.bo[buf].filetype = ft
      vim.bo[buf].modifiable = false
      vim.bo[buf].buftype = "nofile"
      return buf
    end

    local before_buf = make_buf("gitshow://" .. hash .. "^", before_lines)
    local after_buf = make_buf("gitshow://" .. hash, after_lines)

    _gitshow_orig_buf = vim.api.nvim_get_current_buf()
    local orig_win = vim.api.nvim_get_current_win()

    vim.cmd("leftabove vsplit")
    local left_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(left_win, before_buf)
    vim.cmd("diffthis")

    vim.api.nvim_set_current_win(orig_win)
    vim.api.nvim_win_set_buf(orig_win, after_buf)
    vim.cmd("diffthis")
  end)
end

local function gitDiff()
  local gitsigns = require("gitsigns")

  local wins = vim.api.nvim_list_wins()
  for _, win in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(win)
    local name = vim.api.nvim_buf_get_name(buf)
    if name:match("^gitsigns://") then
      vim.api.nvim_win_close(win, true)
      return
    end
    if name:match("^gitshow://") then
      gitShowCommit()
      return
    end
    if name:match("^gitdiff://") then
      gitDiffCommit()
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
      map("n", "<leader>gD", gitDiffCommit, "Git Diff Commit")
      map("n", "<leader>gS", gitShowCommit, "Git Show Commit")
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
    {
      "<leader>gD",
      gitDiffCommit,
      desc = "Git Diff Commit",
    },
    {
      "<leader>gS",
      gitShowCommit,
      desc = "Git Show Commit",
    },
    {
      "<leader>gy",
      gitsource.copy_github_link,
      desc = "Copy link to github",
    },
  },
}
