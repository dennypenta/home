---@brief
--- https://github.com/zigtools/zls
---@type vim.lsp.Config
return {
  cmd = { "zls" },
  filetypes = { "zig", "zir" },
  root_markers = { "zls.json", "build.zig", "build.zig.zon", ".git" },
  workspace_required = false,
  settings = {
    zls = {
      -- Neovim already provides basic syntax highlighting
      semantic_tokens = "partial",
      enable_build_on_save = true,
    },
  },
}
