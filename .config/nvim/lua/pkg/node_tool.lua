local M = {}

local function find(name, bufnr)
  local filename = vim.api.nvim_buf_get_name(bufnr or 0)
  if filename == "" then
    return nil
  end

  local dir = vim.fs.dirname(filename)
  while dir do
    local command = dir .. "/node_modules/.bin/" .. name
    if vim.fn.executable(command) == 1 then
      return command, dir
    end
    local parent = vim.fs.dirname(dir)
    if parent == dir then
      break
    end
    dir = parent
  end
end

local function findPreferred(preferred, fallback, bufnr)
  for _, name in ipairs({ preferred, fallback }) do
    local command, root = find(name, bufnr)
    if command then
      return name, root
    end
  end
  return fallback, vim.fs.root(bufnr or 0, { "package.json", ".git" })
end

--- Returns the formatter name and project directory
--- prefers: oxfmt, prettier
function M.find_formatter(bufnr)
  return findPreferred("oxfmt", "prettier", bufnr)
end

--- Returns the linter name and project directory
--- prefers: oxlint, eslint
function M.find_linter(bufnr)
  return findPreferred("oxlint", "eslint", bufnr)
end

return M
