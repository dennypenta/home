---@type vim.lsp.Config
return {
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
    "--header-insertion=never",
    "--completion-style=detailed",
    "--function-arg-placeholders",
    "--all-scopes-completion",
    "--pch-storage=memory",
    "-j=8",
  },
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
  root_markers = { "compile_commands.json", ".git" },
  workspace_required = false,
}
