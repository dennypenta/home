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
    print(vim.inspect(bps))
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

return {
    "mfussenegger/nvim-dap",
    dependencies = {
        {
            "jbyuki/one-small-step-for-vimkind",
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
            "leoluz/nvim-dap-go",
            opts = {
                dap_configurations = {},
            },
        },
        {
            "jay-babu/mason-nvim-dap.nvim",
            dependencies = "mason.nvim",
            enabled = false,
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
        dap.adapters.go = {
            type = "server",
            port = "38697",
            executable = {
                command = "dlv",
                args = { "dap", "-l", "127.0.0.1:38697" },
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
  -- stylua: ignore
  keys = {
    { "<leader>td", function() require("neotest").run.run({strategy = "dap"}) end, desc = "Debug Nearest" },
    { "<leader>tD", function() require("neotest").run.run({vim.fn.expand("%"), strategy = "dap"}) end, desc = "Debug File" },
    { "<leader>tL", function() require("neotest").run.run_last({strategy = "dap"}) end, desc = "Debug Latest" },

    { "gp", toggle_breakpoint, desc = "Toggle Breakpoint" },
    -- { "<leader>dc", function() require("dap").continue() end, desc = "Run/Continue" },
    { "<F1>", function() require("dap").step_over() end, desc = "Step Over" },
    { "<F2>", function() require("dap").step_into() end, desc = "Step Into" },
    { "<F3>", function() require("dap").step_out() end, desc = "Step Out" },
    { "<F4>", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
    { "<F5>", function() require("dap").down() end, desc = "Down" },
    { "<F6>", function() require("dap").up() end, desc = "Up" },
    { "<F8>", function() require("dap").restart() end, desc = "Restart" },
      { "<leader>dt", function() require("dap").terminate(); require("dapui").close() end, desc = "Terminate" },
  },
    lazy = false,
}
