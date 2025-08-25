return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  pin = true,
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    preset = "modern",
    delay = 20,
    plugins = {
      spelling = {
        enabled = false, -- enabling this will show WhichKey when pressing z= to select spelling suggestions
      },
    },
    triggers = {
      { "<auto>", mode = "nso" },
    },
    spec = {
      {
        mode = { "n", "v" },
        { "<leader><tab>", group = "tabs" },
        { "<leader>c", group = "code" },
        { "<leader>f", group = "file/find" },
        { "gr", group = "LSP" },
        { "<leader>q", group = "Quit" },
        { "<leader>s", group = "Session" },
        { "<leader>j", group = "JSON" },
        { "<leader>l", group = "Lazy" },
        { "<leader>u", group = "UI", icon = { icon = "󰙵 ", color = "cyan" } },
        { "<leader>x", group = "diagnostics/quickfix", icon = { icon = "󱖫 ", color = "green" } },
        { "[", group = "prev" },
        { "]", group = "next" },
        { "g", group = "goto" },
        { "z", group = "fold" },
        {
          "<leader>b",
          group = "buffer",
          expand = function()
            return require("which-key.extras").expand.buf()
          end,
        },
        {
          "<leader>w",
          group = "windows",
          proxy = "<c-w>",
          expand = function()
            return require("which-key.extras").expand.win()
          end,
        },
      },
    },
  },
  keys = {
    {
      "<leader>hl",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Local Keymaps (which-key)",
    },
  },
}
