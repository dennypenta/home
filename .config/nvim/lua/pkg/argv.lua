local M = {}

function M.canStartSession()
  local args = vim.v.argv
  -- just "nvim"
  if #args == 1 then
    return true
  end

  local arg = args[#args]
  return not M.is_file(arg)
end

function M.is_file(arg)
  if vim.fn.isdirectory(arg) == 1 then
    return true
  elseif vim.fn.filereadable(arg) == 1 then
    return true
  else
    return false
  end
end

return M
