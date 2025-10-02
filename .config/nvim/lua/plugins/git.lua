return {
  -- TODO: move signs to stats col
  "lewis6991/gitsigns.nvim",
  pin = true,
  event = "VeryLazy",
  opts = {
    word_diff = false,
    on_attach = function(bufnr)
      local gitsigns = require("gitsigns")

      local function map(mode, l, r, desc)
        vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
      end

      -- Navigation
      map("n", "]g", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]g", bang = true })
        else
          gitsigns.nav_hunk("next")
        end
      end, "next git change")

      map("n", "[g", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[g", bang = true })
        else
          gitsigns.nav_hunk("prev")
        end
      end, "prev git change")

      -- TODO: make it toggle and close if already open
      -- TODO: add checkout to action
      -- TODO: add diff to hash
      map("n", "<leader>gb", function()
        gitsigns.blame()
      end, "Blame Buffer")
      map("n", "<leader>gd", gitsigns.diffthis)

      -- Text object
      map({ "o", "x" }, "ig", gitsigns.select_hunk)
    end,
  },
}
