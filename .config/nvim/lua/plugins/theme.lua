function ToggleTheme()
  local current = vim.g.colors_name

  if current == "kanagawa" then
    vim.o.background = "light"
    vim.cmd.colorscheme("koda")
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
    "oskarnurm/koda.nvim",
    pin = true,
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      require("koda").setup({
        transparent = false,
        -- Style to be applied to different syntax groups
        -- Common use case would be to set either `italic = true` or `bold = true` for a desired group
        -- See `:help nvim_set_hl` for more valid values
        styles = {
          functions = { bold = true },
          keywords = {},
          comments = {},
          strings = {},
          constants = {}, -- includes numbers, booleans
        },
      })
    end,
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
