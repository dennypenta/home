return {
  -- dir = "/Users/d.dvornikov/projects/neotest",
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter",
    {
      "fredrikaverpil/neotest-golang", -- Installation
      dependencies = {
        "leoluz/nvim-dap-go",
      },
    },
    {
      "rcarriga/nvim-dap-ui",
      dependencies = {
        "nvim-neotest/nvim-nio",
        "mfussenegger/nvim-dap",
      },
    },
  },

  opts = {
    -- Can be a list of adapters like what neotest expects,
    -- or a list of adapter names,
    -- or a table of adapter names, mapped to adapter configs.
    -- The adapter will then be automatically loaded with the config.
    -- Example for loading neotest-golang with a custom config
    adapters = {
      ["neotest-golang"] = {
        go_test_args = { "-count=1", "-race", "-v", "-short" },
        dap_go_enabled = false,
      },
    },
    status = { virtual_text = true },
    output = { open_on_run = true },
    quickfix = {
      -- open = function()
      --   if LazyVim.has("trouble.nvim") then
      --     require("trouble").open({ mode = "quickfix", focus = false })
      --   else
      --     vim.cmd("copen")
      --   end
      -- end,
      open = false,
    },
    -- See all config options with :h neotest.Config
    discovery = {
      -- Drastically improve performance in ginormous projects by
      -- only AST-parsing the currently opened buffer.
      enabled = false,
      -- Number of workers to parse files concurrently.
      -- A value of 0 automatically assigns number based on CPU.
      -- Set to 1 if experiencing lag.
      concurrent = 1,
    },
    running = {
      -- Run tests concurrently when an adapter provides multiple commands to run.
      concurrent = false,
    },
    summary = {
      -- Enable/disable animation of icons.
      animated = false,
    },
  },
  config = function(_, opts)
    local neotest = require("neotest")
    local neotest_ns = vim.api.nvim_create_namespace("neotest")
    vim.diagnostic.config({
      virtual_text = {
        format = function(diagnostic)
          -- Replace newline and tab characters with space for more compact diagnostics
          local message = diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
          return message
        end,
      },
    }, neotest_ns)

    opts.consumers = opts.consumers or {}
    if LazyVim.has("trouble.nvim") then
      -- Refresh and auto close trouble after running tests
      ---@type neotest.Consumer
      opts.consumers.trouble = function(client)
        client.listeners.results = function(adapter_id, results, partial)
          if partial then
            return
          end
          local tree = assert(client:get_position(nil, { adapter = adapter_id }))

          local failed = 0
          for pos_id, result in pairs(results) do
            if result.status == "failed" and tree:get_key(pos_id) then
              failed = failed + 1
            end
          end
          vim.schedule(function()
            local trouble = require("trouble")
            if trouble.is_open() then
              trouble.refresh()
              if failed == 0 then
                trouble.close()
              end
            end
          end)
          return {}
        end
      end
    end
    opts.consumers.live = function(client)
      local M = {}
      function M.open(opts)
        opts = opts or {}
        local pos = neotest.run.get_tree_from_args(opts)
        if pos and client:is_running(pos:data().id) then
          neotest.run.attach()
        else
          neotest.output.open({ enter = true })
        end
      end

      return M
    end

    if opts.adapters then
      local adapters = {}
      for name, config in pairs(opts.adapters or {}) do
        if type(name) == "number" then
          if type(config) == "string" then
            config = require(config)
          end
          adapters[#adapters + 1] = config
        elseif config ~= false then
          local adapter = require(name)
          if type(config) == "table" and not vim.tbl_isempty(config) then
            local meta = getmetatable(adapter)
            if adapter.setup then
              adapter.setup(config)
            elseif adapter.adapter then
              adapter.adapter(config)
              adapter = adapter.adapter
            elseif meta and meta.__call then
              adapter = adapter(config)
            else
              error("Adapter " .. name .. " does not support setup")
            end
          end
          adapters[#adapters + 1] = adapter
        end
      end
      vim.api.nvim_create_user_command("NTestOutput", function()
        neotest.run.run()
        local handle
        handle, _ = vim.loop.spawn(
          "sleep",
          { args = { "3s" }, stdio = nil },
          vim.schedule_wrap(function(_)
            handle:close()
            neotest.live.open()
          end)
        )
      end, {})
      opts.adapters = adapters
      neotest.setup(opts)
    end
  end,
  -- stylua: ignore
  keys = {
    {"<leader>t", "", desc = "+test"},
    { "<leader>tI", function() require("plugins.consumers.output_live").open() end, desc = "Run File (Neotest)" },
    { "<leader>tt", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run File (Neotest)" },
    { "<leader>tp", function() require("neotest").run.run(vim.fn.expand("%:p:h")) end, desc = "Run Package (Neotest)" },
    { "<leader>tT", function() require("neotest").run.run(vim.uv.cwd()) end, desc = "Run All Test Files (Neotest)" },
    { "<leader>tr", function() require("neotest").run.run() end, desc = "Run Nearest (Neotest)" },
    { "<leader>tl", function() require("neotest").run.run_last() end, desc = "Run Last (Neotest)" },
    { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Toggle Summary (Neotest)" },
    { "<leader>to", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "Show Output (Neotest)" },
    { "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "Toggle Output Panel (Neotest)" },
    { "<leader>tS", function() require("neotest").run.stop() end, desc = "Stop (Neotest)" },
    -- { "<leader>tw", function() require("neotest").watch.toggle(vim.fn.expand("%")) end, desc = "Toggle Watch (Neotest)" },
    { "[n", function() require("neotest").jump.prev({ status = "failed" }) end, desc = "Jump to previous failed test" },
    { "]n", function() require("neotest").jump.next({ status = "failed" }) end, desc = "Jump to next failed test" },
  },
}
