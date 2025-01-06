return {
    "hrsh7th/nvim-cmp",
    -- version = false, -- last release is way too old
    -- event = "InsertEnter",
    dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "rcarriga/cmp-dap",
        "hrsh7th/cmp-cmdline",
        "saadparwaiz1/cmp_luasnip",
        {
            "L3MON4D3/LuaSnip",
            config = function()
                local ls = require("luasnip")
                ls.config.set_config({
                    history = true, -- Allows jumping back into previous snippets
                    updateevents = "TextChanged,TextChangedI",
                })
                local s = ls.snippet
                local t = ls.text_node
                local i = ls.insert_node

                require("luasnip.loaders.from_vscode").lazy_load() -- Load friendly-snippets or others
                -- Add custom snippets
                ls.add_snippets("go", {
                    s("iferr", {
                        t("if "),
                        i(1, "err"),
                        t(" != nil {"),
                        t({ "", "\t" }),
                        i(0),
                        t({ "", "}" }),
                    }),
                })
            end,
        },
    },
    -- Not all LSP servers add brackets when completing a function.
    -- To better deal with this, LazyVim adds a custom option to cmp,
    -- that you can configure. For example:
    --
    -- ```lua
    -- opts = {
    --   auto_brackets = { "python" }
    -- }
    -- ```

    -- opts = function(_, opts)
    -- opts.snippet = {
    --     expand = function(args)
    --         require("luasnip").lsp_expand(args.body)
    --     end,
    -- }
    -- vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
    -- local cmp = require("cmp")
    -- local defaults = require("cmp.config.default")()
    -- local auto_select = true
    --
    -- local default_sources = cmp.config.sources({
    --     { name = "luasnip" },
    --     { name = "nvim_lsp" },
    --     { name = "path" },
    --     { name = "dap" },
    -- }, {
    --     { name = "buffer" },
    -- })
    -- cmp.setup.filetype({ "dap-repl", "dapui_watches", "dapui_hover" }, {
    --     sources = cmp.config.sources({
    --         { name = "buffer" }, -- Include buffer source for DAP UI
    --     }),
    -- })
    --
    -- local cmp_mapping = cmp.mapping.preset.insert({
    --     ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    --     ["<C-f>"] = cmp.mapping.scroll_docs(4),
    --     ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
    --     ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
    --     ["<C-Space>"] = cmp.mapping.complete(),
    --     ["<CR>"] = LazyVim.cmp.confirm({ select = auto_select }),
    --     ["<C-y>"] = LazyVim.cmp.confirm({ select = true }),
    --     ["<S-CR>"] = LazyVim.cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    --     ["<C-CR>"] = function(fallback)
    --         cmp.abort()
    --         fallback()
    --     end,
    --     ["<Tab>"] = cmp.mapping(function(fallback)
    --         if require("luasnip").expand_or_jumpable() then
    --             require("luasnip").jump(1)
    --         elseif cmp.visible() then
    --             cmp.select_next_item()
    --         else
    --             fallback()
    --         end
    --     end, { "i", "s" }),
    --
    --     ["<S-Tab>"] = cmp.mapping(function(fallback)
    --         if require("luasnip").jumpable(-1) then
    --             require("luasnip").jump(-1)
    --         elseif cmp.visible() then
    --             cmp.select_prev_item()
    --         else
    --             fallback()
    --         end
    --     end, { "i", "s" }),
    --     -- ["<Tab>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
    --     -- ["<S-Tab>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
    --     -- ["<CR>"] = cmp.mapping.confirm({ select = true }),
    -- })
    -- return {
    --     auto_brackets = {}, -- configure any filetype to auto add brackets
    --     completion = {
    --         completeopt = "menu,menuone,noinsert" .. (auto_select and "" or ",noselect"),
    --     },
    --     mapping = cmp_mapping,
    --     preselect = auto_select and cmp.PreselectMode.Item or cmp.PreselectMode.None,
    --     sources = default_sources,
    --     formatting = {
    --         format = function(entry, item)
    --             local icons = LazyVim.config.icons.kinds
    --             if icons[item.kind] then
    --                 item.kind = icons[item.kind] .. item.kind
    --             end
    --
    --             local widths = {
    --                 abbr = vim.g.cmp_widths and vim.g.cmp_widths.abbr or 40,
    --                 menu = vim.g.cmp_widths and vim.g.cmp_widths.menu or 30,
    --             }
    --
    --             for key, width in pairs(widths) do
    --                 if item[key] and vim.fn.strdisplaywidth(item[key]) > width then
    --                     item[key] = vim.fn.strcharpart(item[key], 0, width - 1) .. "…"
    --                 end
    --             end
    --
    --             return item
    --         end,
    --     },
    --     experimental = {
    --         ghost_text = {
    --             hl_group = "CmpGhostText",
    --         },
    --     },
    --     sorting = defaults.sorting,
    -- }
    -- end,
    -- main = "lazyvim.util.cmp",
}
