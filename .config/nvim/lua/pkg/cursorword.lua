-- most of the code is from https://github.com/xiyaowong/nvim-cursorword
-- TODO: consider taking the repo as a plugin
local M = {}
local fn = vim.fn
local api = vim.api

------ core functions -------

local function matchdelete(clear_word)
  if clear_word then
    vim.w.cursorword = nil
  end
  if vim.w.cursorword_match_id then
    pcall(fn.matchdelete, vim.w.cursorword_match_id)
    vim.w.cursorword_match_id = nil
  end
end

local function matchstr(...)
  local ok, ret = pcall(fn.matchstr, ...)
  return ok and ret or ""
end

local function matchadd(disable_filetypes)
  if vim.tbl_contains(disable_filetypes or {}, vim.bo.filetype) then
    return
  end
  local column = api.nvim_win_get_cursor(0)[2]
  local line = api.nvim_get_current_line()

  local left = matchstr(line:sub(1, column + 1), [[\k*$]])
  local right = matchstr(line:sub(column + 1), [[^\k*]]):sub(2)

  local cursorword = left .. right

  if cursorword == vim.w.cursorword then
    return
  end

  vim.w.cursorword = cursorword

  matchdelete()

  if
    #cursorword < (vim.g.cursorword_min_width or 2)
    or #cursorword > (vim.g.cursorword_max_width or 50)
    or cursorword:find("[\192-\255]+")
  then
    return
  end

  cursorword = fn.escape(cursorword, [[~"\.^$[]*]])
  vim.w.cursorword_match_id = fn.matchadd("CursorWord", [[\<]] .. cursorword .. [[\>]], -1)
end

------ setup ------

local timer
function M.set_autocmds()
  local group_id = api.nvim_create_augroup("CursorWord", { clear = true })
  api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = group_id,
    pattern = "*",
    callback = function()
      -- Always clear immediately if we left the word
      local column = api.nvim_win_get_cursor(0)[2]
      local line = api.nvim_get_current_line()

      local left = matchstr(line:sub(1, column + 1), [[\k*$]])
      local right = matchstr(line:sub(column + 1), [[^\k*]]):sub(2)
      local cursorword = left .. right

      if cursorword ~= vim.w.cursorword then
        matchdelete(true)
      end

      -- Cancel previous pending highlight
      if timer then
        timer:stop()
        timer:close()
        timer = nil
      end

      -- Start new timer (e.g., 150ms delay)
      timer = vim.uv.new_timer()
      if timer == nil then
        return
      end
      timer:start(
        300,
        0,
        vim.schedule_wrap(function()
          matchadd()
        end)
      )
    end,
  })
  api.nvim_create_autocmd("WinLeave", {
    group = group_id,
    pattern = "*",
    callback = function()
      matchdelete(true)
    end,
  })
  api.nvim_create_autocmd("ColorScheme", {
    group = group_id,
    pattern = "*",
    callback = function()
      api.nvim_set_hl(0, "CursorWord", { fg = "#C5C9C5", bold = true, default = true })
    end,
  })
end

return M
