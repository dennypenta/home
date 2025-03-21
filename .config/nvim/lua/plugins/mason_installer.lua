return {
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
}
