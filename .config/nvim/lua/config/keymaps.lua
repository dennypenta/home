-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
local function merge_opts(t1, t2)
  local merged = {}
  for k, v in pairs(t1) do
    merged[k] = v
  end
  for k, v in pairs(t2) do
    merged[k] = v
  end
  return merged
end

local opts = { noremap = true, silent = true }

-- ctrl-c as esc
vim.keymap.set("i", "<C-c>", "<Esc>", opts)

-- save file
vim.keymap.set({ "i", "x", "n", "s" }, "<C-s>", "<cmd> w <CR>", opts)

-- quit file
vim.keymap.set("n", "<C-q>", "<cmd> q <CR>", opts)
-- quit
vim.keymap.set("n", "<leader>qq", "<cmd>qa<cr>", opts)

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

-- Clear search with <esc>
vim.keymap.set({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", opts)

-- better indenting
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
vim.keymap.set("n", "n", "'Nn'[v:searchforward].'zv'", merge_opts({ expr = true }, opts))
vim.keymap.set("x", "n", "'Nn'[v:searchforward]", merge_opts({ expr = true }, opts))
vim.keymap.set("o", "n", "'Nn'[v:searchforward]", merge_opts({ expr = true }, opts))
vim.keymap.set("n", "N", "'nN'[v:searchforward].'zv'", merge_opts({ expr = true }, opts))
vim.keymap.set("x", "N", "'nN'[v:searchforward]", merge_opts({ expr = true }, opts))
vim.keymap.set("o", "N", "'nN'[v:searchforward]", merge_opts({ expr = true }, opts))

-- buffers
vim.keymap.set("n", "<S-h>", "<cmd>bprevious<cr>", opts)
vim.keymap.set("n", "<S-l>", "<cmd>bnext<cr>", opts)
vim.keymap.set("n", "[b", "<cmd>bprevious<cr>", opts)
vim.keymap.set("n", "]b", "<cmd>bnext<cr>", opts)
vim.keymap.set("n", "<leader>bd", function()
  Snacks.bufdelete()
end, opts)
vim.keymap.set("n", "<leader>bo", function()
  Snacks.bufdelete.other()
end, opts)
vim.keymap.set("n", "<leader>bD", "<cmd>:bd<cr>", opts)

-- windows
vim.keymap.set("n", "<leader>w", "<c-w>", opts)
vim.keymap.set("n", "<leader>-", "<C-W>s", opts)
vim.keymap.set("n", "<leader>|", "<C-W>v", opts)
vim.keymap.set("n", "<leader>wd", "<C-W>c", opts)

-- tabs
vim.keymap.set("n", "<leader><tab>l", "<cmd>tablast<cr>", opts)
vim.keymap.set("n", "<leader><tab>o", "<cmd>tabonly<cr>", opts)
vim.keymap.set("n", "<leader><tab>f", "<cmd>tabfirst<cr>", opts)
vim.keymap.set("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", opts)
vim.keymap.set("n", "<leader><tab>]", "<cmd>tabnext<cr>", opts)
vim.keymap.set("n", "<leader><tab>d", "<cmd>tabclose<cr>", opts)
vim.keymap.set("n", "<leader><tab>[", "<cmd>tabprevious<cr>", opts)

-- up and down as dispaly lines instead of text lines
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", merge_opts({ expr = true }, opts))
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", merge_opts({ expr = true }, opts))

-- Move to window using the <ctrl> hjkl keys
vim.keymap.set("n", "<C-h>", "<C-w>h", opts)
vim.keymap.set("n", "<C-j>", "<C-w>j", opts)
vim.keymap.set("n", "<C-k>", "<C-w>k", opts)
vim.keymap.set("n", "<C-l>", "<C-w>l", opts)

-- Move Lines
vim.keymap.set("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", opts)
vim.keymap.set("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", opts)
vim.keymap.set("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", opts)
vim.keymap.set("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", opts)
vim.keymap.set("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", opts)
vim.keymap.set("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", opts)

-- floating terminal
vim.keymap.set("n", "<leader>fT", function()
  Snacks.terminal()
end, { desc = "Terminal opts" })
vim.keymap.set("n", "<leader>ft", function()
  Snacks.terminal(nil, { cwd = LazyVim.root() })
end, { desc = "Terminal opts" })
vim.keymap.set("n", "<c-/>", function()
  Snacks.terminal(nil, { cwd = LazyVim.root() })
end, { desc = "Terminal opts" })
vim.keymap.set("t", "<C-/>", "<cmd>close<cr>", opts)

-- lazy
vim.keymap.set("n", "<leader>l", "<cmd>Lazy<cr>", opts)

-- new file
vim.keymap.set("n", "<leader>fn", "<cmd>enew<cr>", opts)

vim.keymap.set("n", "<leader>xl", "<cmd>lopen<cr>", opts)
vim.keymap.set("n", "<leader>xq", "<cmd>copen<cr>", opts)

vim.keymap.set("n", "[q", vim.cmd.cprev, opts)
vim.keymap.set("n", "]q", vim.cmd.cnext, opts)

-- formatting
vim.keymap.set({ "n", "v" }, "<leader>cf", function()
  LazyVim.format({ force = true })
end, opts)

-- Toggle line wrapping
vim.keymap.set("n", "<leader>uw", "<cmd>set wrap!<CR>", opts)

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
