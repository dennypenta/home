local renner = require("pkg.renner")
local vscode = require("pkg.vscode")

local function selectTask(tasks, build)
  vim.ui.select(tasks, {
    format_item = function(task)
      return task.label
    end,
    prompt = "Select program:",
  }, function(task)
    build(task)
  end)
end

local function runFromPreset(build, tasks)
  if #tasks == 1 then
    build(tasks[1])
    return
  end

  selectTask(tasks, build)
end

return {
  "pohlrabi404/compile.nvim",
  event = "VeryLazy",
  pin = true,
  opts = {},
  keys = {
    {
      "<leader>cb",
      function()
        local tasks = vscode.getTasks()
        runFromPreset(renner.build, tasks)
      end,
      desc = "Code Terminal Build",
    },
    {
      "<leader>cB",
      function()
        local tasks = vscode.getWatchers()
        runFromPreset(renner.watch, tasks)
      end,
      desc = "Code Terminal Watch",
    },
    {
      "<leader>ce",
      function()
        require("compile").term.toggle()
      end,
      desc = "Code Terminal Toggle",
    },
  },
}
