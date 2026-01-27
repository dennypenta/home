local M = {}

function M.copy_github_link()
  local file_path = vim.fn.expand("%:p")
  if file_path == "" then
    vim.notify("No file open", vim.log.levels.ERROR)
    return
  end

  local handle = io.popen("git rev-parse --show-toplevel 2>/dev/null")
  local git_root = handle and handle:read("*l")
  if handle then handle:close() end

  if not git_root then
    vim.notify("Not in a git repository", vim.log.levels.ERROR)
    return
  end

  handle = io.popen("git -C " .. vim.fn.shellescape(git_root) .. " config --get remote.origin.url 2>/dev/null")
  local remote_url = handle and handle:read("*l")
  if handle then handle:close() end

  if not remote_url then
    vim.notify("No remote origin found", vim.log.levels.ERROR)
    return
  end

  handle = io.popen("git -C " .. vim.fn.shellescape(git_root) .. " rev-parse HEAD 2>/dev/null")
  local commit_hash = handle and handle:read("*l")
  if handle then handle:close() end

  if not commit_hash then
    vim.notify("Could not get current commit", vim.log.levels.ERROR)
    return
  end

  local github_base = remote_url
    :gsub("git@github%.com:", "https://github.com/")
    :gsub("git@github%.com%-[^:]+:", "https://github.com/")
    :gsub("%.git$", "")

  local rel_path = file_path:sub(#git_root + 2)
  local line_num = vim.fn.line(".")

  local github_url = string.format("%s/blob/%s/%s#L%d", github_base, commit_hash, rel_path, line_num)

  vim.fn.setreg("+", github_url)
  vim.notify("Copied: " .. github_url, vim.log.levels.INFO)
end

return M
