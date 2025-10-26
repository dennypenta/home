local renner = require("pkg.renner")
local signs = require("pkg.icons")
local vscode = require("pkg.vscode")
-- TODO: try not to use $file and the others
-- TODO: remove enrich config when envFile merged: https://github.com/leoluz/nvim-dap-go/pull/115

local signIcons = {
  DapBreakpoint = signs.Dap.Breakpoint,
  DapBreakpointCondition = signs.Dap.BreakpointCondition,
  DapLogPoint = signs.Dap.LogPoint,
  DapStopped = signs.Dap.Stopped,
  DapBreakpointRejected = signs.Dap.BreakpointRejected,
}

local function on_dap_output(lang, output)
  local lines = vim.split(output, "\n")
  renner.outputToErrors(lines)
end

local function enrichConf(finalConfig, on_config)
  if not finalConfig.env then
    -- in order to make it an object, by default an empty {} is an array and the marshalling fails
    finalConfig.env = { ["VIM"] = "1" }
  end
  if finalConfig.envFile then
    local filePath = finalConfig.envFile
    filePath = vscode.substitute(filePath)

    local file = io.open(filePath, "r")
    if not file then
      vim.notify("File not found: " .. filePath, vim.log.levels.ERROR)
    else
      for line in file:lines() do
        local key, value = line:match("([^=]+)=(.+)")
        if key and value then
          value = value:match("^['\"](.-)['\"]$") or value
          finalConfig.env[key] = value
        end
      end
    end
    if file then
      file:close()
    end
  end

  -- for Go adapter to print to stdout
  finalConfig["outputMode"] = "remote"

  local preLaunchTask = finalConfig["preLaunchTask"]
  if not preLaunchTask then
    on_config(finalConfig)
    return
  end

  local task = vscode.find_task(preLaunchTask)
  if not task then
    return vim.notify("no task '" .. preLaunchTask .. "'found", vim.log.levels.ERROR)
  end

  renner.run_task_then({
    task = task,
    on_success = function()
      on_config(finalConfig)
    end,
  })
end

local luaPort = 8086
local goPort = 40000

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
    },
    lazy = false,
    pin = true,
    keys = {
      {
        "<leader>d",
        "",
        desc = "+debug",
        mode = { "n", "v" },
      },
      {
        "gp",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "Toggle Breakpoint",
      },
      {
        "<leader>dP",
        function()
          require("dap").clear_breakpoints()
        end,
        desc = "Clear Breakpoint",
      },
      {
        "<leader>dc",
        function()
          require("dap").continue()
        end,
        desc = "Run/Continue",
      },
      {
        "<leader>dd",
        function()
          require("dap").run_last()
        end,
        desc = "Run Last",
      },
      {
        "<leader>dB",
        function()
          require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end,
        desc = "Breakpoint Condition",
      },
      {
        "<F1>",
        function()
          require("dap").step_over()
        end,
        desc = "Step Over",
      },
      {
        "<F2>",
        function()
          require("dap").step_into()
        end,
        desc = "Step Into",
      },
      {
        "<F3>",
        function()
          require("dap").step_out()
        end,
        desc = "Step Out",
      },
      {
        "<F4>",
        function()
          require("dap").run_to_cursor()
        end,
        desc = "Run to Cursor",
      },
      {
        "<F5>",
        function()
          require("dap").down()
        end,
        desc = "Down",
      },
      {
        "<F6>",
        function()
          require("dap").up()
        end,
        desc = "Up",
      },
      {
        "<leader>ds",
        function()
          require("dap").restart()
        end,
        desc = "Restart",
      },
      {
        "<leader>dt",
        function()
          require("dap").terminate()
        end,
        desc = "Terminate",
      },
      {
        "<leader>dr",
        function()
          require("dap").repl.toggle()
        end,
        desc = "Toggle REPL",
      },
    },
    config = function()
      -- brekapoint signs
      for k, v in pairs(signIcons) do
        vim.fn.sign_define(k, {
          text = v,
          texthl = k,
          linehl = "",
          numhl = "",
        })
      end

      local dap = require("dap")
      dap.adapters = {
        nlua = function(callback, config)
          callback({
            type = "server",
            host = "127.0.0.1",
            port = luaPort,
            blocking = config.blocking,
          })
        end,
        go = {
          type = "server",
          port = goPort,
          executable = {
            command = "dlv",
            args = { "dap", "-l", "127.0.0.1:" .. goPort },
          },
          enrich_config = enrichConf,
        },
        codelldb = {
          type = "server",
          port = "${port}",
          executable = {
            command = "codelldb",
            args = { "--port", "${port}" },
          },
          enrich_config = enrichConf,
        },
      }
      dap.configurations = {
        lua = {
          {
            type = "nlua",
            request = "attach",
            name = "Attach to running Neovim instance",
          },
        },
      }
      dap.listeners.after["event_output"]["this"] = function(session, body)
        if body.category == "stderr" and not session.initialized then
          vim.schedule(function()
            on_dap_output(session.config.type, body.output)
            vim.api.nvim_command("copen")
            local dapui = require("dapui")
            vim.schedule(function()
              dapui.close()
            end)
          end)
        end
      end
      dap.listeners.after["event_initialized"]["this"] = function(session, body)
        vim.fn.setqflist({}, "r", { items = {} })
      end
      local dapui = require("dapui")
      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      -- don't close on termination
      dap.listeners.before.event_terminated.dapui_config = function() end
      dap.listeners.before.event_exited.dapui_config = function() end
    end,
  },
  {
    "leoluz/nvim-dap-go",
    pin = true,
    -- Don't use opts/setup to avoid default configurations
    config = false,
  },
  {
    "jbyuki/one-small-step-for-vimkind",
    pin = true,
    lazy = false,
    dependencies = {
      "mfussenegger/nvim-dap",
    },
    keys = {
      {
        "<leader>dl",
        function()
          require("osv").launch({ port = luaPort })
        end,
        desc = "Debug Lua",
      },
    },
  },
  {
    "rcarriga/nvim-dap-ui",
    pin = true,
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    -- stylua: ignore
    keys = {
      { "<leader>du", function() require("dapui").toggle({}) end, desc = "Dap UI" },
      { "<leader>de", function() require("dapui").eval() end,     desc = "Eval",  mode = { "n", "v" } },
    },
    opts = {
      layouts = {
        {
          elements = {
            { id = "scopes", size = 0.6 },
            { id = "breakpoints", size = 0.2 },
            { id = "stacks", size = 0.2 },
          },
          position = "left",
          size = 40,
        },
        {
          elements = {
            { id = "repl", size = 0.5 },
            { id = "console", size = 0.5 },
          },
          position = "bottom",
          size = 10,
        },
      },
      mappings = {
        edit = "e",
        expand = { "<CR>", "<2-LeftMouse>" },
        open = "<CR>", -- jump to a breakpoint
        remove = "d",
        repl = "r",
        toggle = "t",
      },
    },
  },
}
