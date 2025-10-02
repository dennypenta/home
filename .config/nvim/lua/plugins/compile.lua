local function choose_program(callback)
  if not callback then
    vim.notify("expected callback, given none", vim.log.levels.ERROR)
    return
  end
  local launch_path = vim.fn.getcwd() .. "/.vscode/launch.json"
  local file = io.open(launch_path, "r")
  if not file then
    vim.notify("No .vscode/launch.json found", vim.log.levels.ERROR)
    return
  end

  local content = file:read("*a")
  file:close()

  local ok, data = pcall(vim.json.decode, content)
  if not ok or not data.configurations then
    vim.notify("Invalid launch.json", vim.log.levels.ERROR)
    return
  end

  -- collect candidates
  local items = {}
  for _, cfg in ipairs(data.configurations) do
    if cfg.type == "go" and cfg.mode ~= "remote" then
      if cfg.program then
        table.insert(items, cfg.program)
      end
    end
  end

  if #items == 0 then
    vim.notify("No matching go configurations", vim.log.levels.INFO)
    return
  end

  local call = function(choice)
    if choice then
      local resolved = require("pkg.vscode").substitute(choice)
      callback(resolved)
    end
  end

  if #items == 1 then
    call(items[1])
    return
  end

  -- native menu (nvim 0.6+)
  vim.ui.select(items, { prompt = "Select Go program:" }, call)
end

--- @param cmd string
local function build(cmd)
  -- run async job, pipe to quickfix
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.fn.setqflist({}, "r", { lines = data })
        vim.cmd("cwindow")
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.fn.setqflist({}, "a", { lines = data })
        vim.cmd("cwindow")
      end
    end,
  })
end

local langToCmd = {
  zig = "zig build run",
  go = function(prg)
    return "go run " .. prg
  end,
}

return {
  "pohlrabi404/compile.nvim",
  event = "VeryLazy",
  pin = true,
  opts = {},
  keys = {
    {
      "<leader>cb",
      function()
        local buildCmd = langToCmd[vim.bo.filetype]
        if type(buildCmd) == "string" then
          require("compile").compile(buildCmd)
        else
          choose_program(function(prg)
            local cmd = buildCmd(prg)
            require("compile").compile(cmd)
          end)
        end
      end,
      desc = "Code build",
    },
    -- {
    --   "<leader>cb",
    --   function()
    --     local buildCmd = langToCmd[vim.bo.filetype]
    --     if type(buildCmd) == "string" then
    --       build(buildCmd)
    --     else
    --       choose_program(function(prg)
    --         local cmd = buildCmd(prg)
    --         build(cmd)
    --       end)
    --     end
    --   end,
    --   desc = "Code build",
    -- },
  },
}
