return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {},
  event = "VeryLazy",
  keys = {
    {
      "<leader>me",
      function()
        require("render-markdown").toggle()
      end,
      desc = "[M]arkdown [E]nable",
    },
  },
}
