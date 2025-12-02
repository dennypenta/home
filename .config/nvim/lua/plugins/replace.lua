return {
  "MagicDuck/grug-far.nvim",
  opts = { headerMaxWidth = 80 },
  cmd = "GrugFar",
  keys = {
    {
      "<leader>se",
      function()
        local grug = require("grug-far")
        local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
        grug.toggle_instance({
          instanceName = "far",
          staticTitle = "Find and Replace",
          transient = true,
          prefills = {
            filesFilter = ext and ext ~= "" and "*." .. ext or nil,
          },
        })
      end,
      mode = { "n", "v" },
      desc = "Search and Replace",
    },
    {
      "<leader>sr",
      function()
        local grug = require("grug-far")
        grug.toggle_instance({
          instanceName = "far",
          staticTitle = "Find and Replace",
          transient = true,
        })
      end,
      mode = { "n", "v" },
      desc = "Search and Replace",
    },
    {
      "<leader>sw",
      function()
        local grug = require("grug-far")
        grug.toggle_instance({
          instanceName = "far",
          staticTitle = "Find and Replace",
          transient = true,
          prefills = { search = vim.fn.expand("<cword>") },
        })
      end,
      mode = { "n", "v" },
      desc = "Search and Replace Word",
    },
    {
      "<leader>sg",
      function()
        local grug = require("grug-far")
        grug.toggle_instance({
          engine = "astgrep",
          instanceName = "far",
          staticTitle = "ast-grep",
          transient = true,
        })
      end,
      mode = { "n", "v" },
      desc = "Search and Replace",
    },
    {
      "<leader>sv",
      function()
        local grug = require("grug-far")
        grug.toggle_instance({
          engine = "astgrep",
          instanceName = "far",
          staticTitle = "Find and Replace",
          transient = true,
          visualSelectionUsage = "prefill-search",
        })
      end,
      mode = { "n", "v" },
      desc = "Search and Replace Visual",
    },
  },
}
