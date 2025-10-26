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

local M = {}

---@class DefaultTaskBuilder
---@field tasks? Task[]
---@field fromLaunch? fun(prg: string): string
---@field adapter? string

---@class DefaultWatchBuilder
---@field watchers Task[]

---@class Opts
---@field defaultTaskBuilders table<string, DefaultTaskBuilder>
---@field defaultWatchBuilders table<string, DefaultWatchBuilder>

---@param opts Opts
function M.setup(opts)
  M.defaultTaskBuilders = opts.defaultTaskBuilders
  M.defaultWatchBuilders = opts.defaultWatchBuilders
end

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

---@return Task[]
local function makeDefaultTasks()
  local ft = vim.bo.filetype
  local launchBuilder = M.defaultTaskBuilders[ft]
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
        command = launchBuilder.fromLaunch(cfg.program),
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
  local watchBuilder = M.defaultWatchBuilders[ft]
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

--- Find a task by label
--- @param label string
--- @return Task?
function M.find_task(label)
  local tasks = M.getTasks()
  for _, task in pairs(tasks) do
    if task.label == label then
      return task
    end
  end
  return nil
end

M.setup({
  defaultTaskBuilders = {
    zig = {
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
      fromLaunch = function(prg)
        return "go build " .. prg
      end,
      adapter = "go",
    },
  },
  defaultWatchBuilders = {
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
  },
})

return M
