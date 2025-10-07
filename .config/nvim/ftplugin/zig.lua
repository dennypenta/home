local o = vim.opt_local
o.shiftwidth = 4

local esc = vim.api.nvim_replace_termcodes("<Esc>", true, true, true)

vim.fn.setreg("1", 'yostd.debug.print("' .. esc .. 'pa: {}\\n", .{' .. esc .. "pa});" .. esc)
