--- @class Task
--- @field label string
--- type is a single command (like build) or watch to run a continuous command
--- @field type 'shell' | 'watch'
--- @field command string
--- @field problemMatcher ProblemMatcher?
--- ProblemMatcher defines an error reader format
--- @class ProblemMatcher
--- makes an error format templates based on the language compile error
--- @field base string?
--- @field pattern ProblemPattern?
--- @field background BackgroundMatcher?

--- @class ProblemPattern

--- @class BackgroundMatcher
--- @field beginsPattern string

local M = {}

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

function M.substitute(str)
  for pat, fn in pairs(placeholders) do
    str = str:gsub(pat, fn)
  end
  return str
end

local function readFile(name)
  local path = vim.fn.getcwd() .. "/.vscode/" .. name .. ".json"
  local file = io.open(path, "r")
  if not file then
    vim.notify("No .vscode/" .. name .. ".json found", vim.log.levels.INFO)
    return {}
  end

  local content = file:read("*a")
  file:close()
  content = M.substitute(content)

  local ok, data = pcall(vim.json.decode, content)
  if not ok or not data.configurations then
    vim.notify("Invalid " .. name .. ".json", vim.log.levels.ERROR)
    return {}
  end

  return data
end

local function readLaunch()
  return readFile("launch").configurations
end

--- @return Task[]
local function readTasks()
  return readFile("tasks").tasks
end

function M.getLaunch()
  local configs = readLaunch()
  if not configs then
    return {}
  end

  local copy = {}
  for _, conf in pairs(configs) do
    table.insert(copy, conf)
  end

  return copy
end

local launchBuilders = {
  zig = {
    prg = function(prg)
      return "zig build -fincremental"
    end,
    adapter = "codelldb",
    ---@type Task[]
    tasks = {
      {
        label = "zig build",
        type = "shell",
        command = "zig build -fincremental",
      },
    },
  },
  go = {
    prg = function(prg)
      return "go build " .. prg
    end,
    adapter = "go",
  },
}

local defaultWatchBuilders = {
  zig = {
    ---@type Task[]
    watchers = {
      {
        label = "zig build watch",
        type = "watch",
        command = "zig build -fincremental --watch --debounce 2000",
        problemMatcher = {
          background = {
            beginsPattern = "^Build Summary:",
          },
        },
      },
    },
  },
}

---@return Task[]
local function makeDefaultTasks()
  local ft = vim.bo.filetype
  local launchBuilder = launchBuilders[ft]
  if not launchBuilder then
    vim.notify("no launch build found for ft=" .. ft, vim.log.levels.ERROR)
    return {}
  end

  if launchBuilder.tasks then
    return launchBuilder.tasks
  end

  local configurations = M.getLaunch()
  local tasks = {}
  for _, cfg in ipairs(configurations) do
    if cfg.type == launchBuilder.adapter and cfg.mode ~= "remote" then
      ---@type Task
      local task = {
        label = cfg.name,
        type = "shell",
        command = launchBuilder.prg(cfg.program),
      }
      table.insert(tasks, task)
    end
  end

  return tasks
end

--- @return Task[]
function M.getTasks()
  local copy = {}

  local tasks = readTasks()
  if not tasks then
    return makeDefaultTasks()
  end

  for _, task in pairs(tasks) do
    if task.type == "shell" then
      table.insert(copy, task)
    end
  end

  if #copy == 0 then
    return makeDefaultTasks()
  end

  return copy
end

---@return Task[]
local function makeDefaultWatchers()
  local ft = vim.bo.filetype
  local watchBuilder = defaultWatchBuilders[ft]
  if not watchBuilder then
    vim.notify("no watch builder found for ft=" .. ft, vim.log.levels.ERROR)
    return {}
  end

  if watchBuilder.watchers then
    return watchBuilder.watchers
  end

  return {}
end

--- @return Task[]
function M.getWatchers()
  local copy = {}

  local tasks = readTasks()
  if not tasks then
    return makeDefaultWatchers()
  end

  for _, task in pairs(tasks) do
    if task.type == "watch" then
      table.insert(copy, task)
    end
  end

  if #copy == 0 then
    return makeDefaultWatchers()
  end

  return copy
end

return M
