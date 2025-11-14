vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrw = 1
vim.g.loaded_netrwSettings = 1
vim.g.loaded_netrwFileHandlers = 1
vim.g.loaded_netrw_gitignore = 1

local o = vim.opt

o.mouse = "a"
-- numbers
o.number = true
o.relativenumber = true
o.cursorline = true -- Enable highlighting of the current line
o.wrap = false
o.scrolloff = 4
o.sidescrolloff = 8
-- Default tab and indent step width
o.tabstop = 4
o.shiftwidth = 4
o.smartindent = true
o.autoindent = true
o.softtabstop = 4
o.expandtab = true -- use tab as spaces
-- Case insensitive by default,
-- case-sensitive if a search string contain upper case letters
o.ignorecase = true
o.smartcase = true
o.hlsearch = true
o.incsearch = true
-- adds /g flag to search
o.gdefault = true
-- colors
o.termguicolors = true
o.signcolumn = "yes:2"
-- o.colorcolumn = "120"
vim.cmd("colorscheme retrobox")
o.showmatch = true -- brackets highlighting
o.showmode = true
-- delist menuone in order to exclude builtin completion and make it only using blink.cmp or whatever you like
o.completeopt = "fuzzy,noinsert"
-- opacity of popups and floating windows
o.pumheight = 10
o.pumblend = 10
o.winblend = 15
-- win borders
o.winborder = "shadow"
o.conceallevel = 2 -- Hide * markup for bold and italic, but not markers with substitutions
-- files state
o.backup = false
o.writebackup = false
o.swapfile = false
o.undofile = true
o.undodir = vim.fn.expand("~/.config/nvim/undodir")
o.autowrite = true -- Enable auto write
-- words
o.iskeyword:append("-")
-- search for :find,etc.
o.path:append("**")
o.clipboard = "unnamedplus" -- Sync with system clipboard
o.confirm = true -- Confirm to save changes before exiting modified buffer

-- hotkey leader and secondary leader
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
o.fillchars = {
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}
o.foldlevel = 99 -- never fold
o.grepprg = "rg --vimgrep"
o.jumpoptions = "view" -- show a buffer position on C-I and C-O jumping across the latest
-- cursor positions
o.laststatus = 3 -- global statusline
o.statusline = "%F %= ft=%y %p%% lines=%L[%l,%c]"
o.linebreak = true -- Wrap lines at convenient points, has no effect with wrap=true
o.list = true -- Show some invisible characters (tabs, etc.)
o.ruler = false -- Disable the default ruler
o.sessionoptions = {
  "buffers",
  "curdir",
  "tabpages",
  "winsize",
  "help",
  "globals",
  "skiprtp",
}
o.shiftround = true -- Round indent
o.shortmess = "ltToOcCFWI"
o.spelllang = { "en" }
o.splitbelow = true -- Put new windows below current
o.splitright = true -- Put new windows right of current
o.splitkeep = "screen"
o.timeoutlen = 300 -- Lower than default (1000) to quickly trigger which-key
o.virtualedit = "block" -- Allow cursor to move where there is no text in visual block mode
o.wildmode = "longest:full,full" -- Command-line completion mode
o.winminwidth = 16 -- Minimum window width
o.smoothscroll = true
