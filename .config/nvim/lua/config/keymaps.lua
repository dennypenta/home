local Bufs = require("pkg.bufs")

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
vim.keymap.set("i", "<C-c>", "<Esc>", { noremap = true, silent = true, desc = "Exit insert mode" })
-- save file
vim.keymap.set({ "i", "x", "n", "s" }, "<C-s>", "<cmd> w <CR>", { noremap = true, silent = true, desc = "Save file" })

-- quit file
vim.keymap.set("n", "<C-q>", "<cmd> q <CR>", { noremap = true, silent = true, desc = "Quit file" })
-- quit
vim.keymap.set("n", "<leader>qq", function()
  vim.cmd("wqa")
end, { noremap = true, silent = true, desc = "Quit all files" })

-- visual whole screen
vim.keymap.set("n", "<C-a>", "<S-v>ggoG", { noremap = true, silent = true, desc = "Visual select whole screen" })

-- x without register
vim.keymap.set("n", "x", '"_x', { noremap = true, silent = true, desc = "Delete without register" })

-- -- Vertical scroll and center
vim.keymap.set("n", "}", "}zz", { noremap = true, silent = true, desc = "Scroll a paragraph down and center" })
vim.keymap.set("n", "{", "{zz", { noremap = true, silent = true, desc = "Scroll a paragraph up and center" })

-- Find and center
vim.keymap.set("n", "n", "nzzzv", { noremap = true, silent = true, desc = "Find next and center" })
vim.keymap.set("n", "N", "Nzzzv", { noremap = true, silent = true, desc = "Find previous and center" })

-- Resize with arrows
vim.keymap.set("n", "<Up>", ":resize -2<CR>", { noremap = true, silent = true, desc = "Resize window up" })
vim.keymap.set("n", "<Down>", ":resize +2<CR>", { noremap = true, silent = true, desc = "Resize window down" })
vim.keymap.set("n", "<Left>", ":vertical resize -2<CR>", { noremap = true, silent = true, desc = "Resize window left" })
vim.keymap.set("n", "<Right>", ":vertical resize +2<CR>", { noremap = true, silent = true, desc = "Resize window right" })

-- Clear search with <esc>
vim.keymap.set({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>",
  { noremap = true, silent = true, desc = "Clear search with <esc>" })

-- better indenting
vim.keymap.set("v", "<", "<gv", { desc = "Better indenting (left)" })
vim.keymap.set("v", ">", ">gv", { desc = "Better indenting (right)" })

-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
-- n search forward and N backward whether / or ? is used
vim.keymap.set("n", "n", "'Nn'[v:searchforward].'zv'",
  merge_opts({ expr = true, desc = "Next search result (saner)" }, opts))
vim.keymap.set("x", "n", "'Nn'[v:searchforward]", merge_opts({ expr = true, desc = "Next search result (visual)" }, opts))
vim.keymap.set("o", "n", "'Nn'[v:searchforward]",
  merge_opts({ expr = true, desc = "Next search result (operator)" }, opts))
vim.keymap.set("n", "N", "'nN'[v:searchforward].'zv'",
  merge_opts({ expr = true, desc = "Previous search result (saner)" }, opts))
vim.keymap.set("x", "N", "'nN'[v:searchforward]",
  merge_opts({ expr = true, desc = "Previous search result (visual)" }, opts))
vim.keymap.set("o", "N", "'nN'[v:searchforward]",
  merge_opts({ expr = true, desc = "Previous search result (operator)" }, opts))

-- buffers
vim.keymap.set("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous buffer", noremap = true, silent = true })
vim.keymap.set("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer", noremap = true, silent = true })
vim.keymap.set("n", "[b", "<cmd>bprevious<cr>", { desc = "Previous buffer", noremap = true, silent = true })
vim.keymap.set("n", "]b", "<cmd>bnext<cr>", { desc = "Next buffer", noremap = true, silent = true })

vim.keymap.set("n", "<leader>bd", Bufs.close_current_buf, { desc = "Delete buffer", noremap = true, silent = true })
vim.keymap.set("n", "<leader>bo", Bufs.close_other_bufs, { noremap = true, silent = true, desc = "Close other buffers" })

-- tabs
vim.keymap.set("n", "<leader><tab>l", "<cmd>tablast<cr>", { noremap = true, silent = true, desc = "Go to last tab" })
vim.keymap.set("n", "<leader><tab>o", "<cmd>tabonly<cr>", { noremap = true, silent = true, desc = "Close other tabs" })
vim.keymap.set("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { noremap = true, silent = true, desc = "Go to first tab" })
vim.keymap.set("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { noremap = true, silent = true, desc = "New tab" })
vim.keymap.set("n", "<leader><tab>]", "<cmd>tabnext<cr>", { noremap = true, silent = true, desc = "Next tab" })
vim.keymap.set("n", "<leader><tab>d", "<cmd>tabclose<cr>", { noremap = true, silent = true, desc = "Close tab" })
vim.keymap.set("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { noremap = true, silent = true, desc = "Previous tab" })

-- up and down as dispaly lines instead of text lines
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'",
  merge_opts({ expr = true, desc = "Move down (display line)" }, opts))
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'",
  merge_opts({ expr = true, desc = "Move up (display line)" }, opts))

-- Move to window using the <ctrl> hjkl keys
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window", noremap = true, silent = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to down window", noremap = true, silent = true })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to up window", noremap = true, silent = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window", noremap = true, silent = true })

-- Move Lines
vim.keymap.set("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==",
  { desc = "Move line down", noremap = true, silent = true })
vim.keymap.set("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==",
  { desc = "Move line up", noremap = true, silent = true })
vim.keymap.set("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi",
  { desc = "Move line down in insert mode", noremap = true, silent = true })
vim.keymap.set("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi",
  { desc = "Move line up in insert mode", noremap = true, silent = true })
vim.keymap.set("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv",
  { desc = "Move visual block down", noremap = true, silent = true })
vim.keymap.set("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv",
  { desc = "Move visual block up", noremap = true, silent = true })

-- filetree
vim.keymap.set("n", "<leader>e", ":Explore<CR>", { noremap = true, silent = true, desc = "Open file explorer" })
vim.keymap.set("n", "<leader>ff", ":find", { noremap = true, silent = true, desc = "Find file" })

-- edit nvim
vim.keymap.set("n", "<leader>zn", ":e ~/.config/nvim/init.lua<CR>",
  { noremap = true, silent = true, desc = "Edit nvim config" })
vim.keymap.set("n", "<leader>zz", ":e ~/.zshrc<CR>", { noremap = true, silent = true, desc = "Edit zshrc" })
vim.keymap.set("n", "<leader>zw", ":e ~/.config/wezterm/wezterm.lua<CR>",
  { noremap = true, silent = true, desc = "Edit wezterm" })
vim.keymap.set("n", "<leader>zs", ":e ~/.skhdrc<CR>", { noremap = true, silent = true, desc = "Edit zshrc" })

-- quickfix
local function toggle_qf()
  local qf_window_exists = false
  for _, win_id in ipairs(vim.api.nvim_list_wins()) do
    local win_info = vim.fn.getwininfo(win_id)[1]
    if win_info and win_info.quickfix == 1 then
      qf_window_exists = true
      break
    end
  end

  if qf_window_exists then
    vim.cmd('cclose')
  else
    vim.cmd('copen')
  end
end
vim.keymap.set("n", "<leader>xl", "<cmd>lopen<cr>", { desc = "Open location list", noremap = true, silent = true })
vim.keymap.set("n", "<leader>xq", toggle_qf, { desc = "Open quickfix list", noremap = true, silent = true })
vim.keymap.set("n", "[q", vim.cmd.cprev, { desc = "Previous quickfix item", noremap = true, silent = true })
vim.keymap.set("n", "]q", vim.cmd.cnext, { desc = "Next quickfix item", noremap = true, silent = true })

-- Toggle line wrapping
vim.keymap.set("n", "<leader>uw", "<cmd>set wrap!<CR>", { desc = "Toggle line wrapping", noremap = true, silent = true })

-- Keep last yanked when pasting
vim.keymap.set("v", "p", '"_dP', { desc = "Paste without yanking", noremap = true, silent = true })
-- Disable paste in select mode
vim.keymap.set("s", "p", "p", { noremap = true, desc = "Disable paste in select mode" })

-- Puts an escaped json as a string, useful to paste json object to json as a string value
vim.keymap.set("n", "<leader>je", function()
  -- Get content from system clipboard
  local clipboard_content = vim.fn.getreg("+")

  -- Escape JSON and remove surrounding quotes
  local escaped_json = vim.fn.json_encode(clipboard_content):sub(2, -2)

  -- Insert escaped JSON at the current cursor position
  vim.api.nvim_put({ escaped_json }, "c", true, true)
end, { noremap = true, silent = true, desc = "Put escaped JSON" })
