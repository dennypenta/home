return {
  -- cmdline tools and lsp servers
  {

    "mason-org/mason.nvim",
    cmd = "Mason",
    keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
    build = ":MasonUpdate",
    opts_extend = { "ensure_installed" },
    opts = {
      ensure_installed = {
        "stylua",
        "shfmt",
        "prettier",
        "shellcheck",
        "hadolint",
        "tflint",
        "sqlfluff",
        "markdownlint-cli2",
        "markdown-toc",
        "goimports",
        "gofumpt",
        "gomodifytags",
        "impl",
        "delve",
        "js-debug-adapter",
        "codelldb",
        "bacon",
      },
    },
    ---@param opts MasonSettings | {ensure_installed: string[]}
    config = function(_, opts)
      require("mason").setup(opts)
      local mr = require("mason-registry")
      mr:on("package:install:success", function()
        vim.defer_fn(function()
          -- trigger FileType event to possibly load this newly installed LSP server
          require("lazy.core.handler.event").trigger({
            event = "FileType",
            buf = vim.api.nvim_get_current_buf(),
          })
        end, 100)
      end)

      mr.refresh(function()
        for _, tool in ipairs(opts.ensure_installed) do
          local p = mr.get_package(tool)
          if not p:is_installed() then
            p:install()
          end
        end
      end)
    end,
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = {
          "ast-grep",
          "bash-language-server",
          "docker-compose-language-service",
          "dockerfile-language-server",
          "delve",
          "gofumpt",
          "goimports",
          "golangci-lint",
          "golangci-lint-langserver",
          "golines",
          "gomodifytags",
          "gopls",
          "gotests",
          "gotestsum",
          "hadolint",
          "harper-ls",
          "helm-ls",
          "iferr",
          "impl",
          "js-debug-adapter",
          "json-lsp",
          "json-to-struct",
          "lua-language-server",
          "markdown-toc",
          "markdownlint-cli2",
          "marksman",
          "pyright",
          "ruff",
          "shellcheck",
          "shfmt",
          "sqlfluff",
          "stylua",
          "tailwindcss-language-server",
          "taplo",
          "templ",
          "terraform-ls",
          "tflint",
          "vtsls",
          "yaml-language-server",
          "typescript-language-server",
          "tailwindcss-language-server",
        },
        auto_update = true,
        run_on_start = true,
      })
    end,
  },
}
