-- Show context of the current function
return {
  "nvim-treesitter/nvim-treesitter-context",
  event = "LazyFile",
  opts = { mode = "cursor", max_lines = 3 },
  keys = {
    {
      "<leader>fu",
      function()
        require("treesitter-context").go_to_context(vim.v.count1)
      end,
      desc = "TreesitterContext Up",
    },
  },
}
