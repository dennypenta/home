return {
  "sindrets/diffview.nvim",
  keys = {
    {
      "<leader>gd",
      function()
        local view = require("diffview.lib").get_current_view()

        if view then
          vim.cmd("DiffviewClose")
        else
          vim.cmd("DiffviewOpen")
        end
      end,
      desc = "[G]it [D]iffView Toggle",
    },
    {
      "<leader>gg",
      function()
        Snacks.lazygit({ cwd = LazyVim.root.git() })
      end,
      desc = "Lazygit (Root Dir)",
    },
    {
      "<leader>gG",
      function()
        Snacks.lazygit()
      end,
      desc = "Lazygit (cwd)",
    },
    {
      "<leader>gf",
      function()
        Snacks.lazygit.log_file()
      end,
      desc = "Lazygit Current File History",
    },
    {
      "<leader>gl",
      function()
        Snacks.lazygit.log({ cwd = LazyVim.root.git() })
      end,
      desc = "Lazygit Log",
    },
    {
      "<leader>gL",
      function()
        Snacks.lazygit.log()
      end,
      desc = "Lazygit Log (cwd)",
    },
  },
}
