return {
    "FabijanZulj/blame.nvim",
    opts = {},
    keys = {
        {
            "<leader>bt",
            function()
                vim.cmd("BlameToggle")
            end,
            desc = "BlameToggle",
        },
    },
}
