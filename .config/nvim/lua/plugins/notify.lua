return {
  "rcarriga/nvim-notify",
  pin = true,
  lazy = false,
  config = function()
    require("notify").setup({
      timeout = 10,
    })
    vim.notify = require("notify")
  end,
  keys = {
    { "<leader>nn", "<cmd>Notifications<cr>",                         desc = "Notificiation history" },
    { "<leader>nc", function() require("notify").clear_history() end, desc = "Notificiation clear history" },
  },
}
