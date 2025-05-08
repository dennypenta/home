return {
  "nvimtools/none-ls.nvim",
  event = "LazyFile",
  dependencies = { "williamboman/mason.nvim" },
  init = function()
    LazyVim.on_very_lazy(function()
      -- register the formatter with LazyVim
      LazyVim.format.register({
        name = "none-ls.nvim",
        priority = 200, -- set higher than conform, the builtin formatter
        primary = true,
        format = function(buf)
          return LazyVim.lsp.format({
            bufnr = buf,
            filter = function(client)
              return client.name == "null-ls"
            end,
          })
        end,
        sources = function(buf)
          local ret = require("null-ls.sources").get_available(vim.bo[buf].filetype, "NULL_LS_FORMATTING") or {}
          return vim.tbl_map(function(source)
            return source.name
          end, ret)
        end,
      })
    end)
  end,
  opts = function(_, opts)
    local nls = require("null-ls")
    opts.root_dir = opts.root_dir or require("null-ls.utils").root_pattern(".null-ls-root", "Makefile", ".git")
    opts.sources = vim.list_extend(opts.sources or {}, {
      nls.builtins.formatting.stylua,
      nls.builtins.formatting.shfmt,
      nls.builtins.formatting.prettier,
      nls.builtins.diagnostics.hadolint,
      nls.builtins.formatting.packer,
      nls.builtins.formatting.terraform_fmt,
      nls.builtins.diagnostics.terraform_validate,
      nls.builtins.diagnostics.markdownlint_cli2,
      nls.builtins.code_actions.gomodifytags,
      nls.builtins.code_actions.impl,
      nls.builtins.formatting.goimports,
      nls.builtins.formatting.gofumpt,
    })
  end,
}
