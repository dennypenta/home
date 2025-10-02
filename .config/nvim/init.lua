require("config.options")
-- colors must be activated before LSP
require("config.colors")
require("config.keymaps")
require("config.autocmds")
require("config.ft")
require("config.lsp")
require("config.diagnostic")

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

-- run vi --cmd "lua init_debug=true" to start debugge
if init_debug then
  require("osv").launch({ port = 8086, blocking = true })
end

-- local spinners = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
--
-- local M = {}
-- M.timer = nil
--
-- function M.start(msg)
--   if M.timer then
--     return
--   end
--
--   local i = 1
--   M.timer = vim.loop.new_timer()
--   M.timer:start(
--     0,
--     500,
--     vim.schedule_wrap(function()
--       M.record = vim.notify(spinners[i] .. " " .. msg, vim.log.levels.INFO,
--         { replace = M.record, timeout = 4000 })
--       i = (i % #spinners) + 1
--     end)
--   )
-- end
--
-- function M.stop()
--   if M.timer then
--     M.timer:stop()
--     M.timer:close()
--     M.timer = nil
--     vim.notify("DONE", vim.log.levels.INFO,
--       {
--         replace = M.record,
--         keep = false,
--       })
--     M.record = nil
--   end
--   vim.api.nvim_echo({ { "", "None" } }, false, {}) -- clear
-- end
--
-- vim.api.nvim_create_autocmd("User", {
--   pattern = "VeryLazy",
--   once = true,
--   callback = function()
--     M.start("JOO")
--     vim.defer_fn(M.stop, 3000)
--   end
-- })
