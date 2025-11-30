local loadGithubCopilot = false
local root = vim.fs.root(0, { ".git" })
if root and not string.find(root, "projects/96") then
  vim.notify("github copilot loaded", vim.log.levels.INFO)
  loadGithubCopilot = true
end

local loadGithubCopilot = false

return {
  {
    "github/copilot.vim",
    pin = true,
    enable = loadGithubCopilot,
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
        changes = "review the last changes according to git diff main",
        diagnostics = "There are compile errors in {file}, fix them: {diagnostics}",
        document = "Add documentation to {function}",
        explain = "Explain {this}",
        fix = "fix {this}",
        optimize = "How can {this} be optimized?",
        review = "Can you review {file} for any issues or improvements?",
        test = "I implemented a test for {this}, implement what it defines as expectation and do not change the test",
        test_fix = "There are failing tests in {file}, fix them",
        -----------------------
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
          require("sidekick.cli").send({ msg = "{file}" })
        end,
        desc = "Send File",
      },
      {
        "<leader>av",
        function()
          require("sidekick.cli").send({ msg = "{selection}" })
        end,
        mode = { "x" },
        desc = "Send Visual Selection",
      },
      {
        "<c-.>",
        function()
          require("sidekick.cli").toggle({ focus = true })
        end,
        desc = "Sidekick Toggle",
      },
      {
        "<leader>ac",
        function()
          require("sidekick.cli").toggle({ name = "claude", focus = true })
        end,
        desc = "Sidekick Toggle Claude",
      },
      {
        "<leader>ah",
        function()
          require("sidekick.cli").toggle({ name = "copilot", focus = true })
        end,
        desc = "Sidekick Toggle Copilot",
      },
      {
        "<leader>ag",
        function()
          require("sidekick.cli").toggle({ name = "gemini", focus = true })
        end,
        desc = "Sidekick Toggle Gemini",
      },
      {
        "<leader>ap",
        function()
          require("sidekick.cli").prompt()
        end,
        mode = { "n", "x" },
        desc = "Sidekick Select Prompt",
      },
    },
  },
}
