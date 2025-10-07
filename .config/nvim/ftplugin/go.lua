local o = vim.opt_local
o.shiftwidth = 4

local esc = vim.api.nvim_replace_termcodes("<Esc>", true, true, true)

vim.fn.setreg("1", 'yofmt.Println("' .. esc .. 'pa:"' .. esc .. "1a, " .. esc .. "p1" .. esc .. "1a)" .. esc)
