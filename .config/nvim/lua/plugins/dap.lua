local signs = require("pkg.icons")
-- TODO: try not to use $file and the others
-- TODO: remove enrich config when envFile merged: https://github.com/leoluz/nvim-dap-go/pull/115
-- TODO: dap ui: remove watchers, dapui console

local signIcons = {
  DapBreakpoint = signs.Dap.Breakpoint,
  DapBreakpointCondition = signs.Dap.BreakpointCondition,
  DapLogPoint = signs.Dap.LogPoint,
  DapStopped = signs.Dap.Stopped,
  DapBreakpointRejected = signs.Dap.BreakpointRejected,
}

local lang_to_pattern = {
  go = "^(.-):(%d+):(%d+):%s*(.*)$",
}

local function parse_go_error(lang, line)
  -- example format: "%f:%l:%c: %m"
  -- /path/to/file.go:10:5: error message
  local pattern = lang_to_pattern[lang]
  local file, lnum, col, message = line:match(pattern)
  if file and lnum and col and message then
    return {
      filename = file,
      lnum = tonumber(lnum),
      col = tonumber(col),
      text = message,
      type = "E",
    }
  end
  return nil
end

local function on_dap_output(lang, output)
  local output_lines = vim.split(output, "\n")
  local qflist = {}
  for _, line in ipairs(output_lines) do
    local entry = parse_go_error(lang, line)
    if entry then
      table.insert(qflist, entry)
    end
  end

  if #qflist > 0 then
    vim.fn.setqflist({}, "r", { title = "Go Compilation Errors", items = qflist })
    vim.api.nvim_command("copen")
  end
end

local function enrichConf(finalConfig, on_config)
  local final_config = vim.deepcopy(finalConfig)

  if not final_config.env then
    final_config.env = {}
  end
  -- in order to make it an object, by default an empty {} is an array and the marshalling fails
  final_config.env["VIM"] = "1"

  if final_config.envFile then
    local filePath = final_config.envFile
    filePath = require("pkg.vscode").substitute(filePath)

    local file = io.open(filePath, "r")
    if not file then
      print("File not found: " .. filePath)
    else
      for line in file:lines() do
        local key, value = line:match("([^=]+)=(.+)")
        if key and value then
          value = value:match("^['\"](.-)['\"]$") or value
          final_config.env[key] = value
        end
      end
    end
    if file then
      file:close()
    end
  end

  -- turn on stdout for go
  if final_config["type"] == "go" then
    final_config["outputMode"] = "remote"
  end

  on_config(final_config)
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
          on_dap_output(session.config.type, body.output)
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
    opts = {
      -- useless, prefer having them from .vscode/launch.json
      dap_configurations = {},
      delve = { port = goPort },
    },
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
    opts = {},
  },
}
