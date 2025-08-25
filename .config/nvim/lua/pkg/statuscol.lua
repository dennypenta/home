-- File: lua/my_statuscolumn.lua

local M = {}

-- A simple utility to get the highest-priority sign for a given type.
-- This function mimics the behavior of the original by prioritizing Git signs
-- over other sign types when they exist.
local function find_sign_by_type(signs, sign_type)
  for _, s in ipairs(signs) do
    if s.type == sign_type then
      return s
    end
  end
  return nil
end

-- Main function to be called by the 'statuscolumn' option.
-- This function returns a string that Neovim renders as the status column.
function M.get()
  -- Get the current window and buffer IDs.
  local win = vim.g.statusline_winid
  local buf = vim.api.nvim_win_get_buf(win)

  -- The current line number.
  local lnum = vim.v.lnum

  -- Check if the line has any signs (including Git signs).
  local signs = vim.fn.sign_getplaced(buf, { lnum = lnum, group = "*" })

  local git_sign_text = " " -- A space to fill the column

  -- Check for a Git sign on the current line.
  -- You can identify a Git sign by its name, e.g., 'GitSignsAdd'.
  if signs and signs[1] and signs[1].signs then
    for _, sign_details in ipairs(signs[1].signs) do
      if sign_details.name:find("GitSigns") then
        -- Find the defined sign's text to display.
        local defined_sign = vim.fn.sign_getdefined(sign_details.name)[1]
        if defined_sign then
          git_sign_text = defined_sign.text
          -- Add highlighting using Neovim's `%#` syntax.
          git_sign_text = string.format("%%#%s#%s%%*", defined_sign.texthl, git_sign_text)
        end
        break -- Exit the loop after finding the first Git sign.
      end
    end
  end

  -- Get fold information for the current line.
  local fold_text = " " -- Default to a space.
  vim.api.nvim_win_call(win, function()
    if vim.fn.foldclosed(lnum) >= 0 then
      fold_text = "" -- Closed fold icon.
    elseif vim.fn.foldlevel(lnum) > vim.fn.foldlevel(lnum - 1) then
      fold_text = "" -- Open fold icon.
    end
  end)

  -- Assemble the final string.
  -- The structure is "%<" for left-aligned, "%s" for the sign, "%l" for line number,
  -- and "%>" for right-aligned content.
  -- Here we will put the fold icon on the left and Git icon on the right,
  -- separated by the line number.

  -- Note: The original example has Git signs on the right, so we'll implement that.

  local components = {}

  -- First, add the fold icon on the left side of the line number.
  -- You can add other signs (like LSP) here as well.
  table.insert(components, "%=" .. fold_text .. " ") -- `%` is alignment, ` ` is for spacing.

  -- Add the line number.
  if vim.wo.number or vim.wo.relativenumber then
    if vim.wo.relativenumber and vim.v.relnum ~= 0 then
      table.insert(components, "%r") -- Relative line number
    else
      table.insert(components, "%l") -- Absolute line number
    end
  end

  -- Add a space or filler for spacing.
  table.insert(components, " ")

  -- Now, add the Git sign on the right side.
  table.insert(components, "%>" .. git_sign_text)

  return table.concat(components)
end

return M
