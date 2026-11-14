local node_tool = require("pkg.node_tool")
local function web_formatter(bufnr)
  local name = node_tool.find_formatter(bufnr)
  return { name }
end

return {
  "stevearc/conform.nvim",
  pin = false,
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  config = function()
    require("conform").setup({
      formatters_by_ft = {
        lua = { "stylua" },
        go = { "goimports", "gofmt" },
        javascript = web_formatter,
        javascriptreact = web_formatter,
        typescript = web_formatter,
        typescriptreact = web_formatter,
        json = web_formatter,
        jsonc = web_formatter,
        css = web_formatter,
        scss = web_formatter,
        html = web_formatter,
        yaml = web_formatter,
        markdown = web_formatter,
      },
      format_on_save = {
        lsp_format = "fallback",
        timeout_ms = 1000,
      },
      notify_on_error = true,
    })
  end,
}
