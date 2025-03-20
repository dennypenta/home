-- hotkey leader and secondary leader
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
-- show line numbers
-- TODO: try removing and use opt.number instead
vim.g.number = true
-- show relative numbers
-- TODO: try removing and use opt. instead
vim.g.relativenumber = true
-- LazyVim auto format
vim.g.autoformat = true
-- If the completion engine supports the AI source,
-- use that instead of inline suggestions
vim.g.ai_cmp = true
-- LazyVim picker to use.
-- Can be one of: telescope, fzf
-- Leave it to "auto" to automatically use the picker
-- enabled with `:LazyExtras`
-- TODO: remove telescope and remove this config
vim.g.lazyvim_picker = "auto"
-- LazyVim root dir detection
-- Each entry can be:
-- * the name of a detector function like `lsp` or `cwd`
-- * a pattern or array of patterns like `.git` or `lua`.
-- * a function with signature `function(buf) -> string|string[]`
vim.g.root_spec = { "lsp", { ".git", "lua" }, "cwd" }
-- Set LSP servers to be ignored when used with `util.root.detectors.lsp`
-- for detecting the LSP root
-- TODO: no clue what it does, can try removing
vim.g.root_lsp_ignore = { "copilot" }
-- Hide deprecation warnings
vim.g.deprecation_warnings = false
-- Show the current document symbols location from Trouble in lualine
-- You can disable this for a buffer by setting `vim.b.trouble_lualine = false`
-- TODO: remove and hardcode the value in the plugin
vim.g.trouble_lualine = true
-- Fix markdown indentation settings
vim.g.markdown_recommended_style = 0

local opt = vim.opt

-- Default tab and indent step width
opt.tabstop = 4
opt.shiftwidth = 4
opt.smartindent = true
-- Case insensitive by default,
-- case-sensitive if a search string contain upper case letters
opt.ignorecase = true
opt.smartcase = true
opt.autowrite = true -- Enable auto write
opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus" -- Sync with system clipboard
opt.completeopt = "menu,menuone,noselect" -- show menu on autocomplete
opt.conceallevel = 2 -- Hide * markup for bold and italic, but not markers with substitutions
opt.confirm = true -- Confirm to save changes before exiting modified buffer
opt.cursorline = true -- Enable highlighting of the current line
opt.expandtab = true -- Use spaces instead of tabs
opt.fillchars = {
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}
opt.foldlevel = 99 -- never fold
opt.formatexpr = "v:lua.require'lazyvim.util'.format.formatexpr()"
opt.formatoptions = "jcroqlnt" -- tcqj
opt.grepformat = "%f:%l:%c:%m"
opt.grepprg = "rg --vimgrep"
opt.inccommand = "nosplit" -- preview incremental substitute
opt.jumpoptions = "view" -- show a buffer position on C-I and C-O jumping across the latest cursor positions
opt.laststatus = 3 -- global statusline
opt.linebreak = true -- Wrap lines at convenient points
-- TODO: try removing and see
opt.list = true -- Show some invisible characters (tabs...
opt.mouse = "a" -- Enable mouse mode
opt.number = true -- Print line number
opt.pumblend = 10 -- Popup blend
opt.pumheight = 10 -- Maximum number of entries in a popup
opt.relativenumber = true -- Relative line numbers
opt.ruler = false -- Disable the default ruler
opt.scrolloff = 4 -- Lines of context
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
opt.shiftround = true -- Round indent
opt.shortmess:append({ W = true, I = true, c = true, C = true })
opt.showmode = false -- Dont show mode since we have a statusline
opt.sidescrolloff = 8 -- Columns of context
opt.signcolumn = "yes" -- Always show the signcolumn, otherwise it would shift the text each time
opt.spelllang = { "en" }
opt.splitbelow = true -- Put new windows below current
opt.splitright = true -- Put new windows right of current
opt.splitkeep = "screen"
-- TODO: drop before removing snacks
opt.statuscolumn = [[%!v:lua.require'snacks.statuscolumn'.get()]]
opt.termguicolors = true -- True color support
opt.timeoutlen = vim.g.vscode and 1000 or 300 -- Lower than default (1000) to quickly trigger which-key
opt.undofile = true
opt.undolevels = 1000
opt.updatetime = 5000 -- Save swap file and trigger CursorHold
opt.virtualedit = "block" -- Allow cursor to move where there is no text in visual block mode
opt.wildmode = "longest:full,full" -- Command-line completion mode
opt.winminwidth = 10 -- Minimum window width
opt.wrap = false -- Disable line wrap
opt.smoothscroll = true
opt.foldexpr = "v:lua.require'lazyvim.util'.ui.foldexpr()"
opt.foldmethod = "expr"
opt.foldtext = ""
