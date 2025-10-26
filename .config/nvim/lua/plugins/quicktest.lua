local args_by_ft = {
  go = { "-v", "-failfast", "-race", "short", "-count=1" },
}

local function build_and_debug()
  local quicktest = require("quicktest")
  local compile = require("compile")

  local build_cmd = quicktest.get_build_line("auto", { cmd_override = { "build", "btest", "--summary", "all" } })

  if not build_cmd then
    vim.notify("No build command available", vim.log.levels.ERROR)
    return
  end

  local full_cmd = table.concat(build_cmd, " ")
  require("plugins.compile").buildFunc(full_cmd .. "; echo STATUS:$?", "^STATUS:(%d+)$", function(status)
    if status == "0" then
      compile.destroy()
      quicktest.run_line(nil, "zig", { strategy = "dap" })
    end
  end)
end

return {
  "dennypenta/dashtest.nvim",
  dir = "~/projects/quicktest.nvim",
  config = function()
    local qt = require("quicktest")

    -- update quick test type annotations
    qt.setup({
      adapters = {
        require("quicktest.adapters.golang")(),
        require("quicktest.adapters.zig")({ test_filter_flag = "-Dtest-filter" }),
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
    "pohlrabi404/compile.nvim",
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
      "<leader>tR",
      function()
        local qt = require("quicktest")
        qt.run_line("auto", "auto", { cmd_override = { "build", "btest", "--summary", "all" } })
      end,
      desc = "[T]est Run [L]line",
    },
    -- TODO: for go dap temporary patch cwd, otherwise go doesn't run
    {
      "<leader>td",
      function()
        local qt = require("quicktest")
        qt.run_line("auto", "auto", { strategy = "dap" })
      end,
      desc = "[D]ebug [L]line",
    },
    {
      "<leader>tD",
      function()
        build_and_debug()
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
        local args = args_by_ft[vim.bo.ft] or {}
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
        local ui = require("quicktest.ui")
        ui.get("panel").toggle("split")
      end,
      desc = "[T]est [T]oggle Window",
    },
    {
      "<leader>to",
      function()
        local ui = require("quicktest.ui")
        ui.get("panel").toggle("popup")
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
        local ui = require("quicktest.ui")
        ui.get("summary").toggle()
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
        local ui = require("quicktest.ui")
        ui.get("summary").toggle_failed_filter()
      end,
      desc = "Toggle summary show only failed",
    },
  },
}
