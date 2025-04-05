-- Automatically highlights other instances of the word under your cursor.
-- This works with LSP, Treesitter, and regexp matching to find the other
-- instances.
return {
  {
    "neovim/nvim-lspconfig",
    opts = { document_highlight = { enabled = false } },
  },
}
