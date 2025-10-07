local o = vim.opt_local
o.shiftwidth = 2

local esc = vim.api.nvim_replace_termcodes("<Esc>", true, true, true)

vim.fn.setreg("1", 'yoprint("' .. esc .. 'pa:"' .. esc .. "1a, " .. esc .. "p1" .. esc .. "1a)" .. esc)
