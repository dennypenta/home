require("config.options")
-- colors must be activated before LSP
require("config.colors")
require("config.keymaps")
require("config.autocmds")
require("config.ft")
require("config.lsp")
require("config.diagnostic")
require("pkg.cursorword").set_autocmds()

local Root = require("pkg.root")
Root.to_root()

-- TODO: move to pack, allows resourcing, easy to debug
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- import your plugins
    { import = "plugins" },
    { import = "plugins.langs" },
  },
  change_detection = {
    notify = false,
  },
})
-- lazy
vim.keymap.set("n", "<leader>ll", ":Lazy<cr>", { desc = "Open Lazy.nvim", noremap = true, silent = true })
vim.keymap.set("n", "<leader>lr", ":Lazy reload ", { desc = "Reload Lazy.nvim", noremap = true, silent = true })
