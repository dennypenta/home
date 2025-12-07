local loadGithubCopilot = false
local root = vim.fs.root(0, { ".git" })
if root and not string.find(root, "projects/96") then
  vim.notify("github copilot loaded", vim.log.levels.INFO)
  loadGithubCopilot = true
else
  vim.notify("github copilot not loaded", vim.log.levels.INFO)
end

local lastProvider = "claude"

return {
  {
    "github/copilot.vim",
    pin = true,
    enabled = loadGithubCopilot,
    event = "VeryLazy",
  },
  {
    "folke/sidekick.nvim",
    pin = true,
    event = "VeryLazy",
    opts = {
      jump = {
        jumplist = false,
      },
      nes = {
        enabled = loadGithubCopilot,
        debounce = 350,
      },
      ---@type table<string, sidekick.cli.Config|{}>
      tools = {
        claude = { cmd = { "claude" } },
        copilot = { cmd = { "copilot", "--banner" } },
        gemini = { cmd = { "gemini" } },
      },
      picker = "fzf-lua",
      prompts = {
        buffers = "{buffers}",
        file = "{file}",
        line = "{line}",
        quickfix = "{quickfix}",
        selection = "{selection}",
        ["function"] = "{function}",
        class = "{class}",
      },
    },
    keys = {
      {
        "<tab>",
        function()
          -- if there is a next edit, jump to it, otherwise apply it if any
          if not require("sidekick").nes_jump_or_apply() then
            return "<Tab>" -- fallback to normal tab
          end
        end,
        expr = true,
        desc = "Goto/Apply Next Edit Suggestion",
      },
      {
        "<leader>af",
        function()
          require("sidekick.cli").send({ name = lastProvider, msg = "{file}" })
        end,
        desc = "Send File",
      },
      {
        "<leader>av",
        function()
          require("sidekick.cli").send({ name = lastProvider, msg = "{selection}" })
        end,
        mode = { "x" },
        desc = "Send Visual Selection",
      },
      {
        "<c-.>",
        function()
          require("sidekick.cli").toggle({ name = lastProvider, focus = true })
        end,
        desc = "Sidekick Toggle",
      },
      {
        "<leader>ac",
        function()
          lastProvider = "claude"
          require("sidekick.cli").toggle({ name = "claude", focus = true })
        end,
        desc = "Sidekick Toggle Claude",
      },
      {
        "<leader>ah",
        function()
          lastProvider = "copilot"
          require("sidekick.cli").toggle({ name = "copilot", focus = true })
        end,
        desc = "Sidekick Toggle Copilot",
      },
      {
        "<leader>ag",
        function()
          lastProvider = "gemini"
          require("sidekick.cli").toggle({ name = "gemini", focus = true })
        end,
        desc = "Sidekick Toggle Gemini",
      },
    },
  },
}
