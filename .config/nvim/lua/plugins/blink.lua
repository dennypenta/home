return {
  "Saghen/blink.cmp",
  pin = true,
  version = "1.*",
  -- build = 'cargo build --release',
  -- If you use nix, you can build from source using latest nightly rust with:
  -- build = 'nix run .#build-plugin',

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
    -- 'super-tab' for mappings similar to vscode (tab to accept)
    -- 'enter' for enter to accept
    -- 'none' for no mappings
    --
    -- All presets have the following mappings:
    -- C-space: Open menu or open docs if already open
    -- C-n/C-p or Up/Down: Select next/previous item
    -- C-e: Hide menu
    -- C-k: Toggle signature help (if signature.enabled = true)
    --
    -- See :h blink-cmp-config-keymap for defining your own keymap
    -- TODO: find why p is put in insert mode
    keymap = {
      preset = 'default',
      ['<CR>'] = {
        function(cmp)
          return cmp.select_and_accept()
        end,
        'fallback',
      },
    },
    -- displays
    signature = {
      enabled = true,
      trigger = {
        -- Show the signature help automatically
        enabled = true,
        -- -- Show the signature help window after typing any of alphanumerics, `-` or `_`
        -- show_on_keyword = false,
        -- -- Show the signature help window after typing a trigger character
        -- show_on_trigger_character = true,
        -- -- Show the signature help window when entering insert mode
        -- show_on_insert = true,
        -- -- Show the signature help window when the cursor comes after a trigger character when entering insert mode
        -- show_on_insert_on_trigger_character = true,
      },
    },

    -- (Default) Only show the documentation popup when manually triggered
    completion = {
      -- shows lsp doc like K key
      documentation = { auto_show = true },
      menu = {auto_show = true},
      accept = { auto_brackets = { enabled = true }, },
      list = {
        selection = { preselect = true, auto_insert = false },
      },
    },
    -- Default list of enabled providers defined so that you can extend it
    -- elsewhere in your config, without redefining it, due to `opts_extend`
    sources = {
      -- TODO: add tailwind, css variables
      default = { 'lsp', 'path', 'snippets', 'buffer' },
    },
    -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
    -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
    -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
    --
    -- See the fuzzy documentation for more information
    fuzzy = { implementation = "prefer_rust_with_warning" }
  },
  opts_extend = { "sources.default" },
}
