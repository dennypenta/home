-- TODO: research if the plugin worth it
return {
  "ray-x/go.nvim",
  dependencies = { -- optional packages
    "ray-x/guihua.lua",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("go").setup({
      tag_options = "",
      tag_transform = "camelcase",
      diagnostic = false,
    })
  end,
  ft = { "go", "gomod" },
  keys = {
    {
      "<leader>jg",
      function()
        -- Get content from system clipboard
        local clipboard_content = vim.fn.getreg("+")

        -- Run `gojson` with the clipboard content as input
        local handle = io.popen("echo '" .. clipboard_content:gsub("'", "'\\''") .. "' | gojson -subStruct")
        local gojson_output = handle:read("*a")
        handle:close()

        -- Split the output into lines and remove the first two
        local lines = {}
        for line in gojson_output:gmatch("[^\r\n]+") do
          table.insert(lines, line)
        end
        table.remove(lines, 1)

        -- Insert the modified output at the current cursor position
        vim.api.nvim_put(lines, "c", true, true)
      end,
      desc = "Put JSON as Go",
    },
    {
      "<leader>cg",
      function()
        vim.cmd("GoAddTag")
      end,
      desc = "Add To tags",
    },
    {
      "<leader>ct",
      function()
        vim.cmd("GoAddTest")
      end,
      desc = "Add Go Test",
    },
    {
      "<leader>cr",
      function()
        vim.cmd("GoGenReturn")
      end,
      desc = "Generate Go return values",
    },
    {
      "<leader>cw",
      function()
        local bufnr = vim.api.nvim_get_current_buf()
        local line_num = vim.fn.line(".")
        local line_text = vim.fn.getline(line_num)
        local wrapped_code = string.format("if err := %s; err != nil {\n\t\n}", line_text)

        -- Replace the current line with the wrapped code
        vim.api.nvim_buf_set_text(bufnr, line_num - 1, 0, line_num - 1, #line_text, vim.split(wrapped_code, "\n"))

        -- insert inside the block
        vim.fn.cursor(line_num + 1, 2) -- Move to the second column of the next line
        vim.cmd("startinsert")
      end,
      desc = "Wrap line in if err !=",
    },
    {
      "<leader>ca",
      function()
        vim.cmd("GoAlt")
      end,
      desc = "Go alt file (test)",
    },
  },
}
