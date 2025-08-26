-- consider taking bufdelete plugin
local M = {}

local function get_next_buf(current)
  local buffers, buf_index = {}, 1
  for i, bufinfo in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    if current == bufinfo.bufnr then
      buf_index = i
    end
    table.insert(buffers, bufinfo.bufnr)
  end
  return buffers[buf_index % #buffers + 1]
end

local function switch_buffer(windows, buf)
  local cur_win = vim.fn.winnr()
  for _, winid in ipairs(windows) do
    vim.cmd(string.format("%d wincmd w", vim.fn.win_id2win(winid)))
    vim.cmd(string.format("buffer %d", buf))
  end
  vim.cmd(string.format("%d wincmd w", cur_win))
end

local function is_writable(buf_id)
  local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf_id })
  local modified = vim.api.nvim_get_option_value("modified", { buf = buf_id })
  return buftype == "" and modified
end

function M.close_buf(buf)
  if vim.fn.buflisted(buf) == 0 then
    return
  end
  -- write and close
  if is_writable(buf) then
    vim.api.nvim_buf_call(buf, function()
      vim.cmd("write")
    end)
  end
  -- if the last buffer then switch back and quit
  if #vim.api.nvim_list_bufs() == 1 then
    vim.cmd("q")
  end

  -- retrieve buffer and delete it while preserving window layout
  local windows = vim.fn.getbufinfo(buf)[1].windows
  local next_buf = get_next_buf(buf)
  switch_buffer(windows, next_buf)

  vim.api.nvim_buf_delete(buf, {})
end

function M.close_current_buf()
  local buf_id = vim.api.nvim_get_current_buf()
  M.close_buf(buf_id)
end

function M.close_other_bufs()
  local current_buf_id = vim.api.nvim_get_current_buf()
  local all_buffers = vim.api.nvim_list_bufs()

  for _, buf_id in ipairs(all_buffers) do
    if buf_id ~= current_buf_id then
      M.close_buf(buf_id)
    end
  end
end

return M
