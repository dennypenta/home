local M = {}

M.duration = 160
M.steps = 8

-- recursive animation
local function animate_scroll(remaining_steps, step_size, delay)
  vim.cmd("normal! zz")
  if remaining_steps <= 0 then
    return
  end

  vim.cmd("normal! " .. math.floor(step_size) .. (step_size > 0 and "j" or "k"))

  vim.defer_fn(function()
    animate_scroll(remaining_steps - 1, step_size, delay)
  end, delay)
end

function M.start_scroll(lines, steps, duration)
  local step_size = lines / steps
  local delay = math.floor(duration / steps)
  animate_scroll(steps, step_size, delay)
end

function M.setup(opts)
  if opts then
    for k, v in pairs(opts) do M[k] = v end
  end

  local h = function() return vim.api.nvim_win_get_height(0) end

  -- TODO: up scrolls 4 lines more, fix it
  -- TODO: consider using neoscroll

  local maps = {
    ["<C-d>"] = function() M.start_scroll(h() / 2, M.steps, M.duration) end,
    ["<C-u>"] = function() M.start_scroll(-h() / 2, M.steps, M.duration) end,
    ["<C-f>"] = function() M.start_scroll(h(), M.steps * 2, M.duration * 2) end,
    ["<C-b>"] = function() M.start_scroll(-h(), M.steps * 2, M.duration * 2) end,
    ["<C-e>"] = function() M.start_scroll(8, M.steps / 2, M.duration / 2) end,
    ["<C-y>"] = function() M.start_scroll(-8, M.steps / 2, M.duration / 2) end,
  }

  for lhs, rhs in pairs(maps) do
    vim.keymap.set("n", lhs, rhs, { silent = true, desc = "Animated scroll" })
  end
end

return M
