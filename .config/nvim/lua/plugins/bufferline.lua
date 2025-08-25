local Signs = require("pkg.icons")
local Bufs = require("pkg.bufs")

return {
  'akinsho/bufferline.nvim',
  version = "*",
  pin = true,
  event = "VeryLazy",
  dependencies = 'nvim-tree/nvim-web-devicons',
  opts = {
    options = {
      close_command = Bufs.close_buf,
      right_mouse_command = function(_) end,
      diagnostics = "nvim_lsp",
      iagnostics_indicator = function(_, _, diag)
        local icons = Signs.Diagnostic
        local ret = (diag.error and icons.Error .. diag.error .. " " or "")
        .. (diag.warning and icons.Warn .. diag.warning or "")
        return vim.trim(ret)
      end,
    },
  },
  keys = {
    { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
    { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
    { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
    { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
    { "[B", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer prev" },
    { "]B", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer next" },
    { "<leader>bs", "<cmd>BufferLinePick<cr>", desc = "Buffer Select" },
  },
}

