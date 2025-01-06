return {
  "simrat39/symbols-outline.nvim",
  opts = {},
  keys = {
    {
      "<leader>cb",
      function()
        require("symbols-outline").toggle_outline()
      end,
      desc = "Toggle Outline",
    },
  },
}
