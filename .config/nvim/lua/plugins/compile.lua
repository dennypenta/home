local function choose_program(adapter, callback)
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
    if cfg.type == adapter and cfg.mode ~= "remote" then
      if cfg.program then
        table.insert(items, cfg.program)
      end
    end
  end

  if #items == 0 then
    vim.notify("No matching" .. adapter .. "configurations", vim.log.levels.INFO)
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

  vim.ui.select(items, { prompt = "Select program:" }, call)
end

local langToCmd = {
  zig = {
    prg = "zig build -fincremental",
    adapter = "codelldb",
  },
  go = {
    prg = function(prg)
      return "go run " .. prg
    end,
    adapter = "go",
  },
}

local function build()
  local compile = require("compile").compile
  local buildCmd = langToCmd[vim.bo.filetype]
  if type(buildCmd.prg) == "string" then
    compile(buildCmd.prg)
  else
    choose_program(buildCmd.adapter, function(prg)
      local cmd = buildCmd(prg)
      compile(cmd)
    end)
  end
end

local function filter(lines)
  local cleaned = {}
  for _, l in ipairs(lines or {}) do
    if l:match("%S+:%d+:%d+:") or l:match("%S+|%d+ col %d+|") then
      table.insert(cleaned, l)
    end
  end
  return cleaned
end

local efm = {
  go = "%f:%l:%c: %m",
  zig = "%f:%l:%c: %m",
  default = "%f:%l:%c: %m",
}

local langFilter = {
  zig = "^error: ",
}

local function linesToItems(lines)
  local e = efm[vim.bo.filetype] or efm.default
  local parsed = vim.fn.getqflist({ lines = lines, efm = e })
  local items = {}
  for _, item in pairs(parsed.items or {}) do
    local filename = item.filename
    if not filename and item.bufnr and vim.api.nvim_buf_is_loaded(item.bufnr) then
      filename = vim.api.nvim_buf_get_name(item.bufnr)
    end
    if not filename then
      filename = vim.fn.bufname(item.bufnr)
    end

    local langf = langFilter[vim.bo.filetype]
    if langf and item.text:match(langf) then
      local qitem = {
        filename = vim.fn.fnamemodify(filename, ":p"),
        lnum = item.lnum > 0 and item.lnum - 1 or 0,
        col = item.col > 0 and item.col - 1 or 0,
        end_lnum = item.end_lnum and (item.end_lnum > 0 and item.end_lnum - 1 or nil),
        end_col = item.end_col and (item.end_col > 0 and item.end_col - 1 or nil),
        source = "build",
        text = item.text,
        type = "E",
      }
      table.insert(items, qitem)
    end
  end
  return items
end

local ns = vim.api.nvim_create_namespace("build")
local group = vim.api.nvim_create_augroup("build", { clear = true })

local function toDiagnostic(items)
  if #items == 0 then
    return
  end

  local function set_buf_diagnostics(buf, buf_path)
    if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) or vim.bo[buf].buftype ~= "" then
      return
    end
    if not items or type(items) ~= "table" then
      return
    end

    local ds = {}
    for _, item in ipairs(items or {}) do
      local fname = item.filename and vim.fn.fnamemodify(item.filename, ":p") or nil
      if fname and fname == buf_path then
        table.insert(ds, {
          lnum = item.lnum,
          col = item.col,
          end_lnum = item.end_lnum or item.lnum,
          end_col = item.end_col or item.col,
          severity = vim.diagnostic.severity.ERROR,
          source = item.source or "build",
          message = item.text,
        })
      end
    end
    vim.diagnostic.set(ns, buf, ds, {})
  end
  -- set diagnostics for all currently loaded buffers
  local bufs = vim.tbl_map(function(b)
    return b.bufnr
  end, vim.fn.getbufinfo({ bufloaded = 1, buflisted = 1 }))

  for _, buf in ipairs(bufs) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local buf_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":p")
      set_buf_diagnostics(buf, buf_path)
    end
  end

  -- set diagnostics automatically for future buffers
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = group,
    callback = function(args)
      local buf_path = vim.fn.fnamemodify(args.file, ":p")
      set_buf_diagnostics(args.buf, buf_path)
    end,
  })
end

local function toQf(items)
  if #items == 0 then
    return
  end
  local qf_items = vim.deepcopy(items)
  for _, item in ipairs(qf_items) do
    item.lnum = item.lnum + 1
    if item.end_lnum then
      item.end_lnum = item.end_lnum + 1
    end
  end
  vim.fn.setqflist({}, "r", {
    title = "build",
    items = qf_items,
  })
end

--- @class CompileOutput
--- @field lines string[]
--- @field start_line integer
--- @field end_lien integer
---
--- @return CompileOutput?
local function extract_between_markers(lines, marker_pattern)
  local last_marker_idx = -1
  local second_last_marker_idx = -1

  for i = #lines, 1, -1 do
    if lines[i]:match(marker_pattern) then
      if last_marker_idx == -1 then
        last_marker_idx = i
      else
        second_last_marker_idx = i
        break
      end
    end
  end

  if last_marker_idx == -1 then
    return nil
  end

  local start_line
  local end_line = last_marker_idx - 1

  if second_last_marker_idx ~= -1 then
    start_line = second_last_marker_idx + 1
  else
    start_line = 1
  end

  if end_line < start_line then
    return {}
  end

  local result = {}
  for i = start_line, end_line do
    table.insert(result, lines[i])
  end
  return {
    lines = result,
    start_line = start_line,
    end_line = end_line,
  }
end

local langToWatchCmd = {
  zig = "zig build -fincremental --watch --debounce 2000",
}
local watchMarkers = {
  zig = "^Build Summary:",
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
        local compile = require("compile")

        local buildLines = {}
        vim.diagnostic.reset(ns)
        vim.fn.setqflist({}, "r", { title = "build", items = {} })
        build()

        vim.api.nvim_buf_attach(compile.term.state.buf, false, {
          on_lines = function(_, _, _, first_changed, _, last_changed)
            local lines = vim.api.nvim_buf_get_lines(compile.term.state.buf, first_changed, last_changed, false)

            lines = filter(lines)
            vim.schedule(function()
              if
                not vim.api.nvim_buf_is_valid(compile.term.state.buf)
                or not vim.api.nvim_buf_is_loaded(compile.term.state.buf)
              then
                return
              end

              if #lines > 0 then
                for i in pairs(lines) do
                  table.insert(buildLines, lines[i])
                end
                local items = linesToItems(buildLines)
                toQf(items)
                toDiagnostic(items)
              end
            end)
          end,
        })
      end,
      desc = "Code Terminal Build",
    },
    {
      "<leader>cB",
      function()
        local compile = require("compile")

        local cmd = langToWatchCmd[vim.bo.filetype]
        if not cmd then
          vim.notify("No watch command for " .. vim.bo.filetype, vim.log.levels.WARN)
          return
        end

        local marker = watchMarkers[vim.bo.filetype]
        if not marker then
          vim.notify("No watch marker for " .. vim.bo.filetype, vim.log.levels.WARN)
          return
        end

        vim.diagnostic.reset(ns)
        vim.fn.setqflist({}, "r", { title = "build" })
        compile.compile(cmd)

        local start_line = 0
        vim.api.nvim_buf_attach(compile.term.state.buf, false, {
          on_lines = function(_, _, _, first_changed, _, last_changed)
            local lines = vim.api.nvim_buf_get_lines(compile.term.state.buf, start_line, -1, false)
            local output = extract_between_markers(lines, marker)

            vim.schedule(function()
              if output and output.lines then
                start_line = output.start_line
                local filtered_lines = filter(output.lines)
                if #filtered_lines > 0 then
                  local items = linesToItems(filtered_lines)
                  toQf(items)
                  toDiagnostic(items)
                else
                  -- Clear diagnostics and qf if no errors
                  vim.diagnostic.reset(ns)
                  vim.fn.setqflist({}, "r", { title = "build", items = {} })
                end
              end
            end)
          end,
        })
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
