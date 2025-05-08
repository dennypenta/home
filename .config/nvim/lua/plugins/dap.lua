local breakpoints_path = vim.fn.stdpath("config") .. "/breakpoints.json"
local breakpoints = {}
---Get the saved data for this extension
---@return any
local function save_dap_breakpoints()
  if breakpoints then
    local file = io.open(breakpoints_path, "w")
    if file then
      local content = vim.fn.json_encode(breakpoints)
      file:write(content)
      file:close()
    else
      vim.notify("Error writing breakpoints to file")
    end
  end
end

local function set_restored_breakpoints(buf, file)
  if not breakpoints then
    return
  end
  local bps = breakpoints[file]
  if not bps then
    return
  end
  for _, bp in pairs(bps) do
    local line = bp.line
    local opts = {
      condition = bp.condition,
      log_message = bp.logMessage,
      hit_condition = bp.hitCondition,
    }

    require("dap.breakpoints").set(opts, buf, line)
  end
end

local function restore_dap_breakpoints()
  local file = io.open(breakpoints_path, "r")
  if file then
    local content = file:read("*a")
    breakpoints = vim.fn.json_decode(content)

    file:close()
    local buf = vim.api.nvim_get_current_buf()
    local f = vim.fn.expand("%:p")
    set_restored_breakpoints(buf, f)
  else
    vim.notify("No breakpoints file found")
  end
end

local function toggle_breakpoint()
  local bufnr = vim.api.nvim_get_current_buf()
  local file = vim.fn.expand("%:p")
  require("dap").toggle_breakpoint()

  breakpoints[file] = require("dap.breakpoints").get(bufnr)[bufnr]
  local content = vim.fn.json_encode(breakpoints)
end

-- BufReadPost
vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = { "*" },
  callback = function(ev)
    set_restored_breakpoints(ev.buf, ev.file)
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "PersistenceSavePost",
  callback = save_dap_breakpoints,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "PersistenceLoadPost",
  callback = restore_dap_breakpoints,
})

local function get_args(config)
  local args = type(config.args) == "function" and (config.args() or {}) or config.args or {} --[[@as string[] | string ]]
  local args_str = type(args) == "table" and table.concat(args, " ") or args --[[@as string]]

  config = vim.deepcopy(config)
  ---@cast args string[]
  config.args = function()
    local new_args = vim.fn.expand(vim.fn.input("Run with args: ", args_str)) --[[@as string]]
    if config.type and config.type == "java" then
      ---@diagnostic disable-next-line: return-type-mismatch
      return new_args
    end
    return require("dap.utils").splitstr(new_args)
  end
  return config
end

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "williamboman/mason.nvim",
      "jbyuki/one-small-step-for-vimkind",
      {
        "leoluz/nvim-dap-go",
        opts = {
          dap_configurations = {},
        },
      },
      "rcarriga/nvim-dap-ui",
      -- virtual text for the debugger
      {
        "theHamsta/nvim-dap-virtual-text",
        opts = {},
      },
    },
    optional = true,
    opts = function(_, opts)
      local dap = require("dap")
      local dapui = require("dapui")
      dap.listeners.before.event_terminated.dapui_config = function() end
      dap.listeners.before.event_exited.dapui_config = function() end
      -- require("overseer").enable_dap()
      -- Configure the nlua adapter
      dap.adapters.nlua = function(callback, config)
        callback({ type = "server", host = config.host or "127.0.0.1", port = config.port or 8086 })
      end
      if not dap.adapters["pwa-node"] then
        dap.adapters["pwa-node"] = {
          type = "server",
          host = "localhost",
          port = "${port}",
          executable = {
            command = "node",
            -- 💀 Make sure to update this path to point to your installation
            args = {
              LazyVim.get_pkg_path("js-debug-adapter", "/js-debug/src/dapDebugServer.js"),
              "${port}",
            },
          },
        }
      end
      if not dap.adapters["pwa-chrome"] then
        dap.adapters["pwa-chrome"] = {
          type = "server",
          host = "localhost",
          port = "${port}",
          executable = {
            command = "node",
            -- 💀 Make sure to update this path to point to your installation
            args = {
              LazyVim.get_pkg_path("js-debug-adapter", "/js-debug/src/dapDebugServer.js"),
              "${port}",
            },
          },
        }
      end
      if not dap.adapters["node"] then
        dap.adapters["node"] = function(cb, config)
          if config.type == "node" then
            config.type = "pwa-node"
          end
          local nativeAdapter = dap.adapters["pwa-node"]
          if type(nativeAdapter) == "function" then
            nativeAdapter(cb, config)
          else
            cb(nativeAdapter)
          end
        end
      end
      local js_filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" }

      local vscode = require("dap.ext.vscode")
      vscode.type_to_filetypes["node"] = js_filetypes
      vscode.type_to_filetypes["pwa-node"] = js_filetypes
      vscode.type_to_filetypes["pwa-chrome"] = js_filetypes

      dap.adapters.go = {
        type = "server",
        port = "40000",
        executable = {
          command = "dlv",
          args = { "dap", "-l", "127.0.0.1:40000" },
        },
        enrich_config = function(finalConfig, on_config)
          local final_config = vim.deepcopy(finalConfig)
          -- Placeholder expansion for launch directives
          local placeholders = {
            ["${file}"] = function(_)
              return vim.fn.expand("%:p")
            end,
            ["${fileBasename}"] = function(_)
              return vim.fn.expand("%:t")
            end,
            ["${fileBasenameNoExtension}"] = function(_)
              return vim.fn.fnamemodify(vim.fn.expand("%:t"), ":r")
            end,
            ["${fileDirname}"] = function(_)
              return vim.fn.expand("%:p:h")
            end,
            ["${fileExtname}"] = function(_)
              return vim.fn.expand("%:e")
            end,
            ["${relativeFile}"] = function(_)
              return vim.fn.expand("%:.")
            end,
            ["${relativeFileDirname}"] = function(_)
              return vim.fn.fnamemodify(vim.fn.expand("%:.:h"), ":r")
            end,
            ["${workspaceFolder}"] = function(_)
              return vim.fn.getcwd()
            end,
            ["${workspaceFolderBasename}"] = function(_)
              return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
            end,
            ["${env:([%w_]+)}"] = function(match)
              return os.getenv(match) or ""
            end,
          }

          if not final_config.env then
            final_config.env = {}
          end
          -- in order to make it an object, by default an empty {} is an array and the marshalling fails
          final_config.env["VIM"] = "1"

          if final_config.envFile then
            local filePath = final_config.envFile
            for key, fn in pairs(placeholders) do
              filePath = filePath:gsub(key, fn)
            end

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
        end,
      }

      dap.configurations.lua = {
        {
          type = "nlua",
          request = "attach",
          name = "Attach to running Neovim instance",
        },
      }
      dap.configurations.go = {}
    end,
    config = function()
      vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

      for name, sign in pairs(LazyVim.config.icons.dap) do
        sign = type(sign) == "table" and sign or { sign }
        vim.fn.sign_define(
          "Dap" .. name,
          { text = sign[1], texthl = sign[2] or "DiagnosticInfo", linehl = sign[3], numhl = sign[3] }
        )
      end
      -- setup dap config by VsCode launch.json file
      local vscode = require("dap.ext.vscode")
      local json = require("plenary.json")
      vscode.json_decode = function(str)
        return vim.json.decode(json.json_strip_comments(str))
      end
    end,
  -- stylua: ignore
  keys = {
    { "<leader>d", "", desc = "+debug", mode = {"n", "v"} },
    { "gp", toggle_breakpoint, desc = "Toggle Breakpoint" },
    { "<leader>dc", function() require("dap").continue() end, desc = "Run/Continue" },
    { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
    { "<leader>da", function() require("dap").continue({ before = get_args }) end, desc = "Run with Args" },
    { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = "Breakpoint Condition" },
    { "<F1>", function() require("dap").step_over() end, desc = "Step Over" },
    { "<F2>", function() require("dap").step_into() end, desc = "Step Into" },
    { "<F3>", function() require("dap").step_out() end, desc = "Step Out" },
    { "<F4>", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
    { "<F5>", function() require("dap").down() end, desc = "Down" },
    { "<F6>", function() require("dap").up() end, desc = "Up" },
    { "<F8>", function() require("dap").restart() end, desc = "Restart" },
    { "<leader>dt", function() require("dap").terminate(); require("dapui").close() end, desc = "Terminate" },
    { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
  },
    lazy = false,
  },
  {
    "jbyuki/one-small-step-for-vimkind",
    config = function()
      local dap = require("dap")
      dap.adapters.nlua = function(callback, conf)
        local adapter = {
          type = "server",
          host = conf.host or "127.0.0.1",
          port = conf.port or 8086,
        }
        if conf.start_neovim then
          local dap_run = dap.run
          dap.run = function(c)
            adapter.port = c.port
            adapter.host = c.host
          end
          require("osv").run_this()
          dap.run = dap_run
        end
        callback(adapter)
      end
      dap.configurations.lua = {
        {
          type = "nlua",
          request = "attach",
          name = "Run this file",
          start_neovim = {},
        },
        {
          type = "nlua",
          request = "attach",
          name = "Attach to running Neovim instance (port = 8086)",
          port = 8086,
        },
      }
    end,

    keys = {
      {
        "<leader>dl",
        function()
          require("osv").launch({ port = 8086 })
        end,
        desc = "Debug Lua",
      },
    },
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "nvim-neotest/nvim-nio" },
    -- stylua: ignore
    keys = {
      { "<leader>du", function() require("dapui").toggle({ }) end, desc = "Dap UI" },
      { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = {"n", "v"} },
    },
    opts = {},
    config = function(_, opts)
      local dap = require("dap")
      local dapui = require("dapui")
      dapui.setup(opts)
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open({})
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close({})
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close({})
      end
    end,
  },
}
