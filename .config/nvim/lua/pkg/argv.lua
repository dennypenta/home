local M = {}

function M.is_file()
  local args = vim.v.argv
  -- just "nvim"
  if #args == 1 then return false end
  -- first is nvim, then args
  for i = 2, #args do
    local path = args[i]
    if vim.startswith(path, "-") then goto continue end

    if vim.fn.isdirectory(path) == 1 then
      return true
    elseif vim.fn.filereadable(path) == 1 then
      return true
    else
      return false
    end

    ::continue::
  end

  return false
end

return M
