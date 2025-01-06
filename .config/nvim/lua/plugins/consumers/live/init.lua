local nio = require("nio")

---@type neotest.Client
local client

local neotest = {}

---@toc_entry Live Output Consumer
---@text
--- A consumer that shows test output in real-time as it's being generated.
---@class neotest.consumers.output_live
neotest.output_live = {}

local buf_name = "Neotest Live Output"

---@type integer?
local win_id
---@type integer?
local buf_id
---@type integer?
local current_position_id

local function create_buf()
  if buf_id and nio.fn.bufexists(buf_id) == 1 then
    return buf_id
  end
  buf_id = nio.api.nvim_create_buf(false, true)
  nio.api.nvim_buf_set_name(buf_id, buf_name)

  -- Set buffer options
  nio.api.nvim_buf_set_option(buf_id, "buftype", "nofile")
  nio.api.nvim_buf_set_option(buf_id, "swapfile", false)
  nio.api.nvim_buf_set_option(buf_id, "modifiable", true)
  nio.api.nvim_buf_set_option(buf_id, "filetype", "neotest-output")

  return buf_id
end

local function open_win()
  if win_id and nio.api.nvim_win_is_valid(win_id) then
    return win_id
  end
  local buf = create_buf()

  -- Create window at the bottom
  local width = nio.api.nvim_get_option("columns")
  local height = nio.api.nvim_get_option("lines")
  win_id = nio.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = height - 15,
    col = 0,
    width = width,
    height = 13,
    style = "minimal",
    border = "single",
  })

  return win_id
end

local function append_output(output)
  if not buf_id or nio.fn.bufexists(buf_id) ~= 1 then
    return
  end

  -- Ensure we can modify the buffer
  nio.api.nvim_buf_set_option(buf_id, "modifiable", true)

  local lines = vim.split(output, "\n")
  nio.api.nvim_buf_set_lines(buf_id, -1, -1, false, lines)

  -- Set back to non-modifiable
  nio.api.nvim_buf_set_option(buf_id, "modifiable", false)

  -- Auto-scroll to bottom
  if win_id and nio.api.nvim_win_is_valid(win_id) then
    local line_count = nio.api.nvim_buf_line_count(buf_id)
    nio.api.nvim_win_set_cursor(win_id, { line_count, 0 })
  end
end

---@param args? string|neotest.run.RunArgs Position ID to show output for or args
function neotest.output_live.open(args)
  args = args or {}
  local pos = neotest.run.get_tree_from_args(args)
  if pos and client:is_running(pos:data().id) then
    neotest.run.attach()
  else
    neotest.output.open()
  end
end

neotest.output_live.open = nio.create(neotest.output_live.open, 1)

function neotest.output_live.close()
  if win_id and nio.api.nvim_win_is_valid(win_id) then
    nio.api.nvim_win_close(win_id, true)
    win_id = nil
  end
end

neotest.output_live = setmetatable(neotest.output_live, {
  ---@param client_ neotest.Client
  __call = function(_, client_)
    client = client_
    return neotest.output_live
  end,
})

return neotest.output_live
