return {
    "rebelot/kanagawa.nvim",
    pin = true,
    opts = {
        commentStyle = { italic = false },
        keywordStyle = { italic = false, bold = true},
        -- transparent = true,
        dimInactive = true,
    },
    config = function(_, opts)
        require("kanagawa").setup(opts)
        vim.cmd("colorscheme kanagawa-dragon")
    end
}
