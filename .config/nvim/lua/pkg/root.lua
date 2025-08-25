local M = {}

function M.to_root()
  local handle = io.popen("git rev-parse --show-toplevel 2>/dev/null")
  local git_root = handle and handle:read("*l")
  if handle then handle:close() end
  if git_root then vim.cmd("cd " .. git_root) end
end

local module_markers = {
  "go.mod",
  "stylua.toml",
  "package.json",
}
function M.root_of_module()
  local buf_dir = vim.fn.expand("%:p:h")

  local root_dir = vim.fs.root(0, {module_markers, ".git"})
  if root_dir then
    return root_dir
  end

  return buf_dir
end

return M
