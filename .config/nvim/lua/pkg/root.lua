local M = {}

local module_markers = {
  -- go
  "go.mod",
  "go.work",
  -- lua
  "stylua.toml",
  -- js
  "package.json",
  -- zig
  "build.zig",
  -- fallback
  ".git",
}

function M.to_root()
  -- local handle = io.popen("git rev-parse --show-toplevel 2>/dev/null")
  -- local git_root = handle and handle:read("*l")
  -- if handle then
  --   handle:close()
  -- end
  -- if git_root then
  -- vim.cmd("cd " .. git_root)
  -- end

  local root_dir = vim.fs.root(0, { module_markers })
  vim.cmd("cd " .. root_dir)
end

function M.root_of_module()
  local buf_dir = vim.fn.expand("%:p:h")

  local root_dir = vim.fs.root(0, { module_markers })
  if root_dir then
    return root_dir
  end

  return buf_dir
end

return M
