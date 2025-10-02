local Signs = require("pkg.icons")

return {
  "akinsho/bufferline.nvim",
  version = "*",
  pin = true,
  event = "VeryLazy",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    {
      "ojroques/nvim-bufdel",
      opts = {
        next = function()
          local state = require("bufferline.lazy").require("bufferline.state")
          local index = require("bufferline.commands").get_current_element_index(state)
          if not index then
            return
          end

          local length = #state.components
          local direction = -1
          local next_index = index + direction

          if next_index <= length and next_index >= 1 then
            next_index = index + direction
          elseif index + direction <= 0 then
            next_index = length
          else
            next_index = 1
          end

          local item = state.components[next_index]
          if not item then
            return vim.notify("This " .. item.type .. " does not exist", vim.log.levels.ERROR)
          end
          return item.id
        end,
        quit = true,
      },
    },
  },
  opts = {
    options = {
      close_command = function()
        require("bufdel").delete_buffer_expr()
      end,
      right_mouse_command = function(_) end,
      diagnostics = "nvim_lsp",
      dagnostics_indicator = function(_, _, diag)
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
    {
      "<leader>bd",
      function()
        require("bufdel").delete_buffer_expr(nil, false)
      end,
      desc = "Delete buffer",
    },
    {
      "<leader>bo",
      function()
        require("bufdel").delete_buffer_others(false)
      end,
      desc = "Delete others buffers",
    },
  },
}
