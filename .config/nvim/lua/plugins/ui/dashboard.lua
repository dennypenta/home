local pick = nil

pick = function()
  local fzf_lua = require("fzf-lua")
  local project = require("project_nvim.project")
  local history = require("project_nvim.utils.history")
  local results = history.get_recent_projects()
  local utils = require("fzf-lua.utils")

  local function hl_validate(hl)
    return not utils.is_hl_cleared(hl) and hl or nil
  end

  local function ansi_from_hl(hl, s)
    return utils.ansi_from_hl(hl_validate(hl), s)
  end

  local opts = {
    fzf_opts = {
      ["--header"] = string.format(
        ":: <%s> to %s | <%s> to %s | <%s> to %s | <%s> to %s | <%s> to %s",
        ansi_from_hl("FzfLuaHeaderBind", "ctrl-t"),
        ansi_from_hl("FzfLuaHeaderText", "tabedit"),
        ansi_from_hl("FzfLuaHeaderBind", "ctrl-s"),
        ansi_from_hl("FzfLuaHeaderText", "live_grep"),
        ansi_from_hl("FzfLuaHeaderBind", "ctrl-r"),
        ansi_from_hl("FzfLuaHeaderText", "oldfiles"),
        ansi_from_hl("FzfLuaHeaderBind", "ctrl-w"),
        ansi_from_hl("FzfLuaHeaderText", "change_dir"),
        ansi_from_hl("FzfLuaHeaderBind", "ctrl-d"),
        ansi_from_hl("FzfLuaHeaderText", "delete")
      ),
    },
    fzf_colors = true,
    actions = {
      ["default"] = {
        function(selected)
          fzf_lua.files({ cwd = selected[1] })
        end,
      },
      ["ctrl-t"] = {
        function(selected)
          vim.cmd("tabedit")
          fzf_lua.files({ cwd = selected[1] })
        end,
      },
      ["ctrl-s"] = {
        function(selected)
          fzf_lua.live_grep({ cwd = selected[1] })
        end,
      },
      ["ctrl-r"] = {
        function(selected)
          fzf_lua.oldfiles({ cwd = selected[1] })
        end,
      },
      ["ctrl-w"] = {
        function(selected)
          local path = selected[1]
          local ok = project.set_pwd(path)
          if ok then
            vim.api.nvim_win_close(0, false)
            LazyVim.info("Change project dir to " .. path)
          end
        end,
      },
      ["ctrl-d"] = function(selected)
        local path = selected[1]
        local choice = vim.fn.confirm("Delete '" .. path .. "' project? ", "&Yes\n&No")
        if choice == 1 then
          history.delete_project({ value = path })
        end
        pick()
      end,
    },
  }

  fzf_lua.fzf_exec(results, opts)
end

return {
  { "folke/snacks.nvim", opts = { dashboard = { enabled = false } } },
  {
    "nvimdev/dashboard-nvim",
    lazy = false, -- As https://github.com/nvimdev/dashboard-nvim/pull/450, dashboard-nvim shouldn't be lazy-loaded to properly handle stdin.
    opts = function()
      local logo = [[
         ██████╗  ██████╗     ███╗   ██╗██╗   ██╗██╗███╗   ███╗
        ██╔════╝ ██╔═══██╗    ████╗  ██║██║   ██║██║████╗ ████║
        ██║  ███╗██║   ██║    ██╔██╗ ██║██║   ██║██║██╔████╔██║
        ██║   ██║██║   ██║    ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║
        ╚██████╔╝╚██████╔╝    ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║
         ╚═════╝  ╚═════╝     ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝
]]

      logo = string.rep("\n", 8) .. logo .. "\n\n"

      local opts = {
        theme = "doom",
        hide = {
          -- this is taken care of by lualine
          -- enabling this messes up the actual laststatus setting after loading a file
          statusline = false,
        },
        config = {
          header = vim.split(logo, "\n"),
          -- stylua: ignore
          center = {
            { action = 'lua LazyVim.pick()()',                           desc = " Find File",       icon = " ", key = "f" },
            { action = "ene | startinsert",                              desc = " New File",        icon = " ", key = "n" },
            { action = 'lua LazyVim.pick("oldfiles")()',                 desc = " Recent Files",    icon = " ", key = "r" },
            { action = pick,                                             desc = " Projects",        icon = " ", key = "p", key_format = "  %s", },
            { action = 'lua LazyVim.pick("live_grep")()',                desc = " Find Text",       icon = " ", key = "g" },
            { action = 'lua LazyVim.pick.config_files()()',              desc = " Config",          icon = " ", key = "c" },
            { action = 'lua require("persistence").load()',              desc = " Restore Session", icon = " ", key = "s" },
            { action = "LazyExtras",                                     desc = " Lazy Extras",     icon = " ", key = "x" },
            { action = "Lazy",                                           desc = " Lazy",            icon = "󰒲 ", key = "l" },
            { action = function() vim.api.nvim_input("<cmd>qa<cr>") end, desc = " Quit",            icon = " ", key = "q" },
          },
          footer = function()
            local stats = require("lazy").stats()
            local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
            return { "⚡ Neovim loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms .. "ms" }
          end,
        },
      }

      for _, button in ipairs(opts.config.center) do
        button.desc = button.desc .. string.rep(" ", 43 - #button.desc)
        button.key_format = "  %s"
      end

      -- open dashboard after closing lazy
      if vim.o.filetype == "lazy" then
        vim.api.nvim_create_autocmd("WinClosed", {
          pattern = tostring(vim.api.nvim_get_current_win()),
          once = true,
          callback = function()
            vim.schedule(function()
              vim.api.nvim_exec_autocmds("UIEnter", { group = "dashboard" })
            end)
          end,
        })
      end

      return opts
    end,
    keys = {
      { "<leader>fp", pick, desc = "Projects" },
    },
  },
}
