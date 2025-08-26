local args_by_ft = {
  go = { "-v", "-failfast", "-race", "short", "-count=1" },
}

return {
  "dennypenta/quicktest.nvim",
  config = function()
    local qt = require("quicktest")

    -- update quick test type annotations
    qt.setup({
      adapters = {
        require("quicktest.adapters.golang")(),
      },
      ui = {
        require("quicktest.ui.panel")({ default_win_mode = "split" }),
        require("quicktest.ui.diagnostics")(),
        require("quicktest.ui.quickfix")({ enabled = true, open = false }),
        require("quicktest.ui.summary")({ join_to_panel = true, only_failed = true, enabled = true }),
      },
    })
  end,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
  },
  keys = {
    {
      "<leader>tr",
      function()
        local qt = require("quicktest")
        qt.run_line()
      end,
      desc = "[T]est Run [L]line",
    },
    {
      "<leader>td",
      function()
        local qt = require("quicktest")
        qt.run_line("auto", "auto", { strategy = "dap" })
      end,
      desc = "[D]ebug [L]line",
    },
    {
      "<leader>tf",
      function()
        local qt = require("quicktest")

        qt.run_file()
      end,
      desc = "[T]est Run [F]ile",
    },
    {
      "<leader>tp",
      function()
        local qt = require("quicktest")

        qt.run_dir()
      end,
      desc = "[T]est Run [D]ir",
    },
    {
      "<leader>ta",
      function()
        local qt = require("quicktest")
        local args = args_by_ft[vim.bo.ft]
        if not args then
          local msg = string.format("no args for ft=%s found", vim.bo.ft)
          return vim.notify(msg, vim.log.levels.ERROR)
        end

        qt.run_all("auto", "auto", { additional_args = args })
      end,
      desc = "[T]est Run [A]ll",
    },
    {
      "<leader>tl",
      function()
        local qt = require("quicktest")

        qt.run_previous()
      end,
      desc = "[T]est Run [P]revious",
    },
    {
      "<leader>tt",
      function()
        local qt = require("quicktest")

        qt.toggle_win("split")
      end,
      desc = "[T]est [T]oggle Window",
    },
    {
      "<leader>to",
      function()
        local qt = require("quicktest")

        qt.toggle_win("popup")
      end,
      desc = "[T]est [T]oggle Window",
    },
    {
      "<leader>tc",
      function()
        local qt = require("quicktest")

        qt.cancel_current_run()
      end,
      desc = "[T]est [C]ancel Current Run",
    },
    {
      "<leader>ts",
      function()
        local qt = require("quicktest")

        qt.toggle_summary()
      end,
      desc = "[T]est [S]ummary",
    },
    {
      "]n",
      function()
        local qt = require("quicktest")
        qt.next_failed_test()
      end,
      desc = "Next failed test",
    },
    {
      "[n",
      function()
        local qt = require("quicktest")
        qt.prev_failed_test()
      end,
      desc = "Prev failed test",
    },
    {
      "<leader>tS",
      function()
        local qt = require("quicktest")
        qt.toggle_summary_failed_filter()
      end,
      desc = "Toggle summary show only failed",
    },
  },
}
