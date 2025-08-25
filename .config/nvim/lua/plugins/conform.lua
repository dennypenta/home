return {
  'stevearc/conform.nvim',
  pin = true,
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  config = function()
    require("conform").setup({
      formatters_by_ft = {
        lua = { "stylua" },
        go = { "goimports", "gofmt" },
      },
      format_on_save = {
        lsp_format = "fallback",
        timeout_ms = 1000,
      },
      notify_on_error = true,
    })
  end,
}
