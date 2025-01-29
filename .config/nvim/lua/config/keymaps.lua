-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("i", "<C-c>", "<Esc>", { noremap = true })
local opts = { noremap = true, silent = true }

-- save file
vim.keymap.set("n", "<C-s>", "<cmd> w <CR>", opts)

-- quit file
vim.keymap.set("n", "<C-q>", "<cmd> q <CR>", opts)

-- visual whole screen
vim.keymap.set("n", "<C-a>", "<S-v>ggoG")

-- x without register
vim.keymap.set("n", "x", '"_x', opts)

-- -- Vertical scroll and center
-- vim.keymap.set("n", "<C-d>", "<C-d>zz", opts)
-- vim.keymap.set("n", "<C-u>", "<C-u>zz", opts)

-- Find and center
vim.keymap.set("n", "n", "nzzzv", opts)
vim.keymap.set("n", "N", "Nzzzv", opts)

-- Resize with arrows
vim.keymap.set("n", "<Up>", ":resize -2<CR>", opts)
vim.keymap.set("n", "<Down>", ":resize +2<CR>", opts)
vim.keymap.set("n", "<Left>", ":vertical resize -2<CR>", opts)
vim.keymap.set("n", "<Right>", ":vertical resize +2<CR>", opts)

-- Toggle line wrapping
vim.keymap.set("n", "<leader>cw", "<cmd>set wrap!<CR>", opts)

-- Keep last yanked when pasting
vim.keymap.set("v", "p", '"_dP', opts)

-- Puts an escaped json as a string, useful to paste json object to json as a string value
vim.keymap.set("n", "<leader>je", function()
  -- Get content from system clipboard
  local clipboard_content = vim.fn.getreg("+")

  -- Escape JSON and remove surrounding quotes
  local escaped_json = vim.fn.json_encode(clipboard_content):sub(2, -2)

  -- Insert escaped JSON at the current cursor position
  vim.api.nvim_put({ escaped_json }, "c", true, true)
end, { noremap = true, silent = true, desc = "Put escaped JSON" })

-- Puts a json object as a go struct
-- github.com/ChimeraCoder/gojson/gojson
vim.keymap.set("n", "<leader>jg", function()
  -- Get content from system clipboard
  local clipboard_content = vim.fn.getreg("+")

  -- Run `gojson` with the clipboard content as input
  local handle = io.popen("echo '" .. clipboard_content:gsub("'", "'\\''") .. "' | gojson -subStruct")
  local gojson_output = handle:read("*a")
  handle:close()

  -- Split the output into lines and remove the first two
  local lines = {}
  for line in gojson_output:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end
  table.remove(lines, 1)

  -- Insert the modified output at the current cursor position
  vim.api.nvim_put(lines, "c", true, true)
end, { noremap = true, silent = true, desc = "Put JSON as Go" })

-- Go tags
vim.keymap.set("n", "<leader>ct", function()
  vim.cmd("GoAddTag")
end)

-- Go tests
vim.keymap.set("n", "<leader>cg", function()
  vim.cmd("GoAddTest")
end)

-- Go gen ret values
vim.keymap.set("n", "<leader>ce", function()
  vim.cmd("GoGenReturn")
end)

-- Iferr
vim.keymap.set("n", "<leader>ci", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local line_num = vim.fn.line(".")
  local line_text = vim.fn.getline(line_num)
  local wrapped_code = string.format("if err := %s; err != nil {\n\t\n}", line_text)

  -- Replace the current line with the wrapped code
  vim.api.nvim_buf_set_text(bufnr, line_num - 1, 0, line_num - 1, #line_text, vim.split(wrapped_code, "\n"))

  -- insert inside the block
  vim.fn.cursor(line_num + 1, 2) -- Move to the second column of the next line
  vim.cmd("startinsert")
end)
