return {
    "vinnymeller/swagger-preview.nvim",
    cmd = { "SwaggerPreview", "SwaggerPreviewStop", "SwaggerPreviewToggle" },
    build = "npm i",
    config = true,
    keys = {
        {
            "<leader>cp",
            function()
                vim.cmd("SwaggerPreview")
            end,
            desc = "SwaggerPreviewToggle",
        },
    },
}
