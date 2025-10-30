local ignore_pattern = { ".git" }
local root = require("pkg.root")

return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = { "BufEnter" },
  pin = true,
  config = function()
    local actions = require("fzf-lua").actions
    require("fzf-lua").setup({
      winopts = {
        fullscreen = true,
      },
      files = {
        no_ignore = false,
        hidden = true,
      },
      grep = {
        no_ignore = false,
        hidden = true,
      },
      actions = {
        files = {
          true, -- uncomment to inherit all the below in your custom config
          -- Pickers inheriting these actions:
          --   files, git_files, git_status, grep, lsp, oldfiles, quickfix, loclist,
          --   tags, btags, args, buffers, tabs, lines, blines
          -- `file_edit_or_qf` opens a single selection or sends multiple selection to quickfix
          -- replace `enter` with `file_edit` to open all files/bufs whether single or multiple
          -- replace `enter` with `file_switch_or_edit` to attempt a switch in current tab first
          -- ["enter"]       = actions.file_edit_or_qf,
          -- ["ctrl-s"]      = actions.file_split,
          -- ["ctrl-v"]      = actions.file_vsplit,
          -- ["ctrl-t"]      = actions.file_tabedit,
          -- ["alt-q"]       = actions.file_sel_to_qf,
          -- ["alt-Q"]       = actions.file_sel_to_ll,
          -- ["alt-g"]       = actions.toggle_ignore,
          -- ["alt-h"]       = actions.toggle_hidden,
          -- ["alt-f"]       = actions.toggle_follow,
        },
      },

      keymap = {
        -- Below are the default binds, setting any value in these tables will override
        -- the defaults, to inherit from the defaults change [1] from `false` to `true`
        builtin = {
          -- neovim `:tmap` mappings for the fzf win
          true, -- uncomment to inherit all the below in your custom config
          ["<F1>"] = "toggle-help",
          ["<S-Left>"] = "preview-reset",
          ["<S-down>"] = "preview-page-down",
          ["<S-up>"] = "preview-page-up",
        },
        fzf = {
          -- fzf '--bind=' options
          true, -- uncomment to inherit all the below in your custom config
          ["ctrl-d"] = "half-page-down",
          ["ctrl-u"] = "half-page-up",
          ["ctrl-b"] = "beginning-of-line",
          ["ctrl-e"] = "end-of-line",
          ["ctrl-h"] = "first",
          ["ctrl-l"] = "last",
          ["shift-down"] = "preview-page-down",
          ["shift-up"] = "preview-page-up",
          ["ctrl-q"] = "select-all+accept",
        },
      },
    })
    require("fzf-lua").register_ui_select()
  end,
  keys = {
    -- find files
    {
      "<leader><leader>",
      function()
        require("fzf-lua").files({})
      end,
      desc = "Fzf files",
    },
    {
      "<leader>ff",
      function()
        require("fzf-lua").files({ cmd = "rg --files", rg_opts = [[--color=never --hidden --files --no-ignore]] })
      end,
      desc = "Fzf files + .git",
    },
    {
      "<leader>fm",
      function()
        local cwd = root.root_of_module()
        require("fzf-lua").files({
          cwd = cwd,
          cmd = "rg --files",
          rg_opts = [[--color=never --hidden --files --no-ignore]],
        })
      end,
      desc = "Fzf files + .git",
    },
    -- buffers
    {
      "<leader>bf",
      function()
        require("fzf-lua").buffers()
      end,
      desc = "Fzf buffers",
    },
    -- search
    {
      "<leader>/",
      function()
        -- default opts + fixed-strings
        require("fzf-lua").live_grep({
          file_ignore_patterns = ignore_pattern,
          rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096 --fixed-strings -e",
        })
      end,
      desc = "Fzf search (plain string)",
    },
    {
      "<C-/>",
      function()
        -- default opts + fixed-strings
        require("fzf-lua").live_grep({
          file_ignore_patterns = ignore_pattern,
          resume = true,
          rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096 --fixed-strings -e",
        })
      end,
      desc = "Fzf search last (plain text)",
    },
    {
      "<leader>fs",
      function()
        -- default opts + fixed-strings
        require("fzf-lua").live_grep({
          rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096 --fixed-strings -e",
        })
      end,
      desc = "Fzf search + .git (plain string)",
    },
    -- grep
    {
      "<leader>fg",
      function()
        require("fzf-lua").live_grep({ file_ignore_patterns = ignore_pattern })
      end,
      desc = "Fzf grep (regex)",
    },
    {
      "<leader>fG",
      function()
        require("fzf-lua").live_grep({ file_ignore_patterns = ignore_pattern, resume = true })
      end,
      desc = "Fzf grep last (regex)",
    },
    -- commands
    {
      "<leader>:",
      function()
        require("fzf-lua").command_history()
      end,
      desc = "Fzf command history",
    },
    -- git
    {
      "<leader>gs",
      function()
        require("fzf-lua").git_status()
      end,
      desc = "Fzf git status",
    },
    {
      "<leader>gc",
      function()
        require("fzf-lua").git_commits()
      end,
      desc = "Fzf git commits",
    },
    -- colors
    {
      "<leader>uc",
      function()
        require("fzf-lua").colorschemes({
          colors = { "retrobox", "habamax", "kanagawa-lotus", "kanagawa-dragon" },
        })
      end,
      desc = "Fzf colorscheme",
    },
    {
      "<leader>ho",
      function()
        require("fzf-lua").nvim_options()
      end,
      desc = "Fzf nvim options",
    },
    -- help
    {
      "<leader>hk",
      function()
        require("fzf-lua").keymaps()
      end,
      desc = "Fzf keymaps",
    },
    {
      "gra",
      function()
        require("fzf-lua").lsp_code_actions()
      end,
      desc = "LSP code action",
    },
    -- lsp
    {
      "gri",
      function()
        require("fzf-lua").lsp_implementations()
      end,
      desc = "LSP implementations",
    },
    {
      "grd",
      function()
        require("fzf-lua").lsp_definitions()
      end,
      desc = "LSP definition",
    },
    {
      "grr",
      function()
        require("fzf-lua").lsp_references()
      end,
      desc = "LSP references",
    },
    {
      "grt",
      function()
        require("fzf-lua").lsp_typedefs()
      end,
      desc = "LSP type definitions",
    },
    -- diagnostic
    {
      "<leader>xf",
      function()
        require("fzf-lua").quickfix()
      end,
      desc = "Fzf quickfix",
    },
    {
      "<leader>xd",
      function()
        require("fzf-lua").diagnostics_document()
      end,
      desc = "Diagnostic Document",
    },
    {
      "<leader>xw",
      function()
        require("fzf-lua").diagnostics_workspace()
      end,
      desc = "Diagnostic Workspace",
    },
  },
}
