local Root = require("pkg.root")

local function open(uri)
  local cmd
  if vim.fn.has("win32") == 1 then
    cmd = { "explorer", uri }
  elseif vim.fn.has("macunix") == 1 then
    cmd = { "open", uri }
  else
    if vim.fn.executable("xdg-open") == 1 then
      cmd = { "xdg-open", uri }
    elseif vim.fn.executable("wslview") == 1 then
      cmd = { "wslview", uri }
    else
      cmd = { "open", uri }
    end
  end

  local ret = vim.fn.jobstart(cmd, { detach = true })
  if ret <= 0 then
    local msg = {
      "Failed to open uri",
      ret,
      vim.inspect(cmd),
    }
    vim.notify(table.concat(msg, "\n"), vim.log.levels.ERROR)
  end
end

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    pin = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    lazy = false,
    config = function()
      local opts = {
        close_if_last_window = false,
        open_files_do_not_replace_types = {
          "terminal",
          "trouble",
          "qf",
          "dapui_scopes",
          "dapui_stacks",
          "dapui_breakpoints",
          "dap-repl",
        },
        default_component_configs = {
          file_size = { enabled = false },
        },
        window = {
          position = "float",
          mappings = {
            ["Y"] = {
              function(state)
                local node = state.tree:get_node()
                local path = node:get_id()
                vim.fn.setreg("+", path, "c")
              end,
              desc = "Copy Path to Clipboard",
            },
            ["O"] = {
              function(state)
                open(state.tree:get_node().path)
              end,
              desc = "Open with System Application",
            },
            ["I"] = {
              function(state)
                local path = state.tree:get_node().path
                local path = vim.fs.dirname(path)
                open(path)
              end,
              desc = "Open parent with System Application",
            },
            ["F"] = {
              function(state)
                require("fzf-lua").live_grep({
                  search_paths = state.tree:get_node().path,
                  rg_opts = "--smart-case --fixed-strings",
                })
              end,
              desc = "Live grep in the node",
            },
            ["<cr>"] = "open",
            -- ["<esc>"] = "cancel", -- close preview or floating neo-tree window
            ["<esc>"] = {
              function(state)
                require("neo-tree.sources." .. state.name .. ".commands")["revert_preview"](state)
                require("neo-tree.sources." .. state.name .. ".commands")["cancel"](state)
              end,
              desc = "close preview and floating tree window",
            },
            ["<space>"] = {
              -- TODO: show preview forever
              "toggle_preview",
              config = {
                use_float = true,
                use_snacks_image = false,
                use_image_nvim = false,
              },
            },
            -- Read `# Preview Mode` for more information
            ["l"] = "focus_preview",
            ["S"] = "open_split",
            ["s"] = "open_vsplit",
            ["z"] = "close_all_nodes",
            ["Z"] = "expand_all_nodes",
            ["a"] = {
              "add",
              -- this command supports BASH style brace expansion ("x{a,b,c}" -> xa,xb,xc). see `:h neo-tree-file-actions` for details
              -- some commands may take optional config options, see `:h neo-tree-mappings` for details
              config = {
                show_path = "none", -- "none", "relative", "absolute"
              },
            },
            ["A"] = "add_directory", -- also accepts the optional config.show_path option like "add". this also supports BASH style brace expansion.
            ["d"] = "delete",
            ["r"] = "rename",
            ["b"] = "rename_basename",
            ["y"] = "copy_to_clipboard",
            ["p"] = "paste_from_clipboard",
            ["c"] = "copy", -- takes text input for destination, also accepts the optional config.show_path option like "add":
            -- ["c"] = {
            --  "copy",
            --  config = {
            --    show_path = "none" -- "none", "relative", "absolute"
            --  }
            --}
            ["m"] = "move", -- takes text input for destination, also accepts the optional config.show_path option like "add".
            ["q"] = "close_window",
            ["R"] = "refresh",
            ["?"] = "show_help",
            ["<"] = "prev_source",
            [">"] = "next_source",
            ["i"] = "show_file_details",
            -- ["i"] = {
            --   "show_file_details",
            --   -- format strings of the timestamps shown for date created and last modified (see `:h os.date()`)
            --   -- both options accept a string or a function that takes in the date in seconds and returns a string to display
            --   -- config = {
            --   --   created_format = "%Y-%m-%d %I:%M %p",
            --   --   modified_format = "relative", -- equivalent to the line below
            --   --   modified_format = function(seconds) return require('neo-tree.utils').relative_date(seconds) end
            --   -- }
            -- },        },
          },
        },
        filesystem = {
          bind_to_cwd = false, -- changes cwd every toggle
          filtered_items = {
            visible = true, -- when true, they will just be displayed differently than normal items
            hide_dotfiles = false,
            hide_gitignored = false,
            hide_hidden = false, -- only works on Windows for hidden files/directories
            never_show = { -- remains hidden even if visible is toggled to true, this overrides always_show
              ".DS_Store",
              "undodir",
              --"thumbs.db"
            },
          },
          follow_current_file = {
            enabled = false, -- This will find and focus the file in the active buffer every time
            --               -- the current file is changed while the tree is open.
            leave_dirs_open = false, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
          },
          group_empty_dirs = true, -- when true, empty folders will be grouped together
          hijack_netrw_behavior = "open_default", -- netrw disabled, opening a directory opens neo-tree
          -- in whatever position is specified in window.position
          -- "open_current",  -- netrw disabled, opening a directory opens within the
          -- window like netrw would, regardless of window.position
          -- "disabled",    -- netrw left alone, neo-tree does not handle opening dirs
          use_libuv_file_watcher = false, -- This will use the OS level file watchers to detect changes
          -- instead of relying on nvim autocmd events.
          window = {
            mappings = {
              ["<bs>"] = "navigate_up",
              ["."] = "set_root",
              ["/"] = "fuzzy_finder",
              ["D"] = "fuzzy_finder_directory",
              ["[g"] = "prev_git_modified",
              ["]g"] = "next_git_modified",
              ["o"] = {
                "show_help",
                nowait = false,
                config = { title = "Order by", prefix_key = "o" },
              },
              ["oc"] = { "order_by_created", nowait = false },
              ["od"] = { "order_by_diagnostics", nowait = false },
              ["og"] = { "order_by_git_status", nowait = false },
              ["om"] = { "order_by_modified", nowait = false },
              ["on"] = { "order_by_name", nowait = false },
              ["os"] = { "order_by_size", nowait = false },
              ["ot"] = { "order_by_type", nowait = false },
              -- ['<key>'] = function(state) ... end,
            },
            fuzzy_finder_mappings = { -- define keymaps for filter popup window in fuzzy_finder_mode
              ["<C-n>"] = "move_cursor_down",
              ["<C-p>"] = "move_cursor_up",
            },
          },
          commands = {}, -- Add a custom command or override a global one using the same function name
          event_handlers = {
            {
              event = require("neo-tree.events").FILE_MOVED,
              handler = function(data)
                print(vim.inspect(data))
              end,
            },
            {
              event = require("neo-tree.events").FILE_RENAMED,
              handler = function(data)
                print(vim.inspect(data))
              end,
            },
          },
        },
      }
      require("neo-tree").setup(opts)
    end,
    keys = {
      {
        "<leader>e",
        function()
          require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd() })
        end,
        desc = "Explorer NeoTree (Root Dir)",
        remap = true,
      },
      {
        "<leader>E",
        function()
          local root_dir = Root.root_of_module()
          require("neo-tree.command").execute({ toggle = true, dir = root_dir })
        end,
        desc = "Explorer NeoTree (Package Dir)",
        remap = true,
      },
      {
        "<leader>r",
        function()
          require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd(), reveal = true })
          -- require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd(), reveal = true })
          -- local state = require("neo-tree.sources.manager").get_state_for_window()
          -- require("neo-tree.sources." .. state.name .. ".commands")["preview"](state)
        end,
        desc = "Explorer NeoTree (Root Dir)",
        remap = true,
      },
      {
        "<leader>R",
        function()
          local root_dir = Root.root_of_module()
          require("neo-tree.command").execute({ toggle = true, dir = root_dir, reveal = true })
        end,
        desc = "Explorer NeoTree (Package Dir)",
        remap = true,
      },
      {
        "<leader>ge",
        function()
          require("neo-tree.command").execute({ source = "git_status", toggle = true })
        end,
        desc = "Git Explorer",
      },
      {
        "<leader>be",
        function()
          require("neo-tree.command").execute({ source = "buffers", toggle = true })
        end,
        desc = "Buffer Explorer",
      },
    },
  },
  {
    "antosha417/nvim-lsp-file-operations",
    pin = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-neo-tree/neo-tree.nvim", -- makes sure that this loads after Neo-tree.
    },
    config = function()
      require("lsp-file-operations").setup()
    end,
  },
}
