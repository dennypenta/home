-- there is an issue to restore a session in a lazy floating window
-- adding a new plugin requires opening it again using <leader>ll or :Lazy
return {
  "folke/persistence.nvim",
  event = "VeryLazy",
  pin = true,
  opts = {
    branch = false,
  },
  config = function(_, opts)
    require("persistence").setup(opts)
    vim.schedule(function()
      local Argv = require("pkg.argv")
      -- when a file is not specified, just "nvim", then start the session for the project respecting git directory
      if not Argv.is_file() then
        if vim.bo.ft == 'lazy' then
          vim.cmd.quit()
        end
        require("persistence").load()
      else
        -- otherwise just read the specified file, do staff and stop, no session
        require("persistence").stop()
      end
    end)
  end,
  keys = {
    { "<leader>ol", function() require("persistence").load() end,           desc = "Restore Session" },
    { "<leader>os", function() require("persistence").select() end,         desc = "Select Session" },
    { "<leader>oS", function() require("persistence").save() end,           desc = "Save Session" },
    { "<leader>oc", function() print(require("persistence").current()) end, desc = "Current Session" },
  },
}
