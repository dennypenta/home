function ToggleTheme()
  local current = vim.g.colors_name

  if current == "kanagawa" then
    vim.o.background = "light"
    vim.cmd.colorscheme("modus")
  else
    vim.o.background = "dark"
    vim.cmd.colorscheme("kanagawa")
  end
end

return {
  {
    "rebelot/kanagawa.nvim",
    pin = true,
    opts = {
      commentStyle = { italic = false },
      keywordStyle = { italic = false, bold = true },
      transparent = true,
      dimInactive = true,
      background = {
        dark = "dragon",
        light = "lotus",
      },
      theme = "dragon",
    },
    config = function(_, opts)
      require("kanagawa").setup(opts)
      vim.cmd("colorscheme kanagawa")
    end,
  },
  {
    "miikanissi/modus-themes.nvim",
    pin = true,
    opts = {
      style = "modus_operandi",
      transparent = false,
      dim_inactive = true,
      sign_column_background = true,
      styles = {
        comments = { italic = false },
        keywords = { italic = false, bold = true },
        functions = {},
        variables = {},
      },
    },
    keys = {
      {
        "<leader>uc",
        ToggleTheme,
        mode = { "n" },
        desc = "Switch dark/light mode",
      },
    },
  },
}
