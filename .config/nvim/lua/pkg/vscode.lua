local M = {}

local placeholders = {
  ["${file}"] = function(_)
    return vim.fn.expand("%:p")
  end,
  ["${fileBasename}"] = function(_)
    return vim.fn.expand("%:t")
  end,
  ["${fileBasenameNoExtension}"] = function(_)
    return vim.fn.fnamemodify(vim.fn.expand("%:t"), ":r")
  end,
  ["${fileDirname}"] = function(_)
    return vim.fn.expand("%:p:h")
  end,
  ["${fileExtname}"] = function(_)
    return vim.fn.expand("%:e")
  end,
  ["${relativeFile}"] = function(_)
    return vim.fn.expand("%:.")
  end,
  ["${relativeFileDirname}"] = function(_)
    return vim.fn.fnamemodify(vim.fn.expand("%:.:h"), ":r")
  end,
  ["${workspaceFolder}"] = function(_)
    return vim.fn.getcwd()
  end,
  ["${workspaceFolderBasename}"] = function(_)
    return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  end,
  ["${env:([%w_]+)}"] = function(match)
    return os.getenv(match) or ""
  end,
}

function M.substitute(str)
  for pat, fn in pairs(placeholders) do
    str = str:gsub(pat, fn)
  end
  return str
end

return M
