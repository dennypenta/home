return {
  "mason-org/mason.nvim",
  pin = true,
  config = function(_, opts)
    require("mason").setup(opts)

    local ensure_installed = {
      -- LSPs
      "lua-language-server",
      "gopls",
      "zls",
      -- formatters
      "stylua",
      "rust-analyzer",
    }

    vim.api.nvim_create_user_command("MasonInstallAll", function()
      local packages = table.concat(ensure_installed, " ")
      vim.cmd("MasonInstall " .. packages)
    end, {})
  end,
}
