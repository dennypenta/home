vim.lsp.enable({
  "lua_ls",
  "gopls",
  "zls",
  -- TODO: enable linked editing range for web
})


vim.fn.sign_define("LspCodeLensSign", {
  text = "▶",
  texthl = "LspCodeLensSign",
  linehl = "",
  numhl = ""
})

local function place_codelens_signs(lenses, bufnr)
  if vim.fn.buflisted(bufnr) == 0 then return end

  vim.fn.sign_unplace("codelens", { buffer = bufnr })

  if not lenses then return end

  local line_has_lens = {}
  for _, lens in pairs(lenses) do
    local line = lens.range.start.line + 1
    if line_has_lens[line] then goto continue end

    vim.fn.sign_place(0, "codelens", "LspCodeLensSign", bufnr, { lnum = line, priority = 10 })
    line_has_lens[line] = true

    ::continue::
  end
end

local function enable(client, bufnr)
  if client:supports_method("textDocument/inlayHint") then
    vim.lsp.inlay_hint.enable(true, { bufnr })
  end

  -- update code lens
  if client:supports_method("textDocument/codeLens") then
    local original_display = vim.lsp.codelens.display
    vim.lsp.codelens.display = function(lenses, lens_bufnr, client_id)
      original_display(lenses, lens_bufnr, client_id)
      place_codelens_signs(lenses, lens_bufnr)
    end

    vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
      buffer = bufnr,
      callback = function()
        vim.lsp.codelens.refresh()
      end,
    })
  end
end

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then
      vim.notify("failed to get LSP client", vim.log.levels.ERROR, {})
      assert(client)
    end

    -- if client:supports_method('textDocument/completion') then
    --   vim.lsp.completion.enable(true, ev.data.client_id, ev.buf, { autotrigger = true })
    -- end
    enable(client, ev.buf)
  end,
})

-- vim.lsp.handlers['client/registerCapability'] = (function(overridden)
--   return function(err, res, ctx)
--     local result = overridden(err, res, ctx)
--     local client = vim.lsp.get_client_by_id(ctx.client_id)
--     if not client then
--       return
--     end
--     for bufnr, _ in pairs(client.attached_buffers) do
--       enable(client, bufnr)
--     end
--     return result
--   end
-- end)(vim.lsp.handlers['client/registerCapability'])

vim.keymap.set("n", "grl", vim.lsp.codelens.run, { desc = "Run code lens" })
vim.keymap.set("n", "grt", vim.lsp.buf.type_definition, { desc = "Go to Definition", noremap = true })
vim.keymap.set("n", "grd", vim.lsp.buf.definition, { desc = "Go to Definition", noremap = true })
vim.keymap.set("n", "grr", vim.lsp.buf.references, { desc = "Go to Reference", noremap = true })
vim.keymap.set("n", "grn", vim.lsp.buf.rename, { desc = "Rename", noremap = true })
vim.keymap.set("n", "gri", vim.lsp.buf.implementation, { desc = "Go to Implementation", noremap = true })
vim.keymap.set("n", "gra", vim.lsp.buf.code_action, { desc = "Code Actions", noremap = true })
---- default S-K may be changed, depends on keywordprg option
-- -- e.g. for go look in  /opt/homebrew/Cellar/neovim/0.11.1/share/nvim/runtime/ftplugin/go.vim
vim.keymap.set("n", "<S-K>", vim.lsp.buf.hover, { desc = "Hover doc", noremap = true })
