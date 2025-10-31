return {
  "igorlfs/nvim-dap-view",
  enabled = false,
  ---@module 'dap-view'
  ---@type dapview.Config
  opts = {
    winbar = {
      sections = { "scopes", "breakpoints", "threads", "repl", "" },
      default_section = "scopes",
    },
    windows = {
      height = 0.25,
      position = "below",
      terminal = {
        width = 0.4,
        position = "right",
        -- Hide the terminal when starting a new session
        start_hidden = false,
      },
    },
  },
  keys = {
    {
      "<leader>du",
      function()
        require("dap-view").toggle()
      end,
      desc = "Dap UI",
    },
    {
      "<leader>dB",
      function()
        require("dap-view").jump_to_view("breakpoints")
      end,
      desc = "Dap UI",
    },
    {
      "<leader>dR",
      function()
        require("dap-view").jump_to_view("repl")
      end,
      desc = "Dap UI",
    },
    {
      "<leader>dT",
      function()
        require("dap-view").jump_to_view("threads")
      end,
      desc = "Dap UI",
    },
    {
      "<leader>dS",
      function()
        require("dap-view").jump_to_view("scopes")
      end,
      desc = "Dap UI",
    },
  },
}
