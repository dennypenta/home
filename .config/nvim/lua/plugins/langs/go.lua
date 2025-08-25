local function choose_go_program(callback)
  if not callback then
    vim.notify("expected callback, given none", vim.log.levels.ERROR)
    return
  end
  local launch_path = vim.fn.getcwd() .. "/.vscode/launch.json"
  local file = io.open(launch_path, "r")
  if not file then
    vim.notify("No .vscode/launch.json found", vim.log.levels.ERROR)
    return
  end

  local content = file:read("*a")
  file:close()

  local ok, data = pcall(vim.json.decode, content)
  if not ok or not data.configurations then
    vim.notify("Invalid launch.json", vim.log.levels.ERROR)
    return
  end

  -- collect candidates
  local items = {}
  for _, cfg in ipairs(data.configurations) do
    if cfg.type == "go" and cfg.mode ~= "remote" then
      if cfg.program then
        table.insert(items, cfg.program)
      end
    end
  end

  if #items == 0 then
    vim.notify("No matching go configurations", vim.log.levels.INFO)
    return
  end

  -- native menu (nvim 0.6+)
  vim.ui.select(items, { prompt = "Select Go program:" }, function(choice)
    if choice then
      local resolved = require("pkg.vscode").substitute(choice)
      callback(resolved)
    end
  end)
end

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
      "<leader>cw",
      function()
        vim.cmd("GoIfErr")
      end,
      desc = "Add line if err !=",
    },
    {
      "<leader>cB",
      function()
        local buf_path = vim.api.nvim_buf_get_name(0)
        if buf_path == "" then
          return nil
        end
        local package = vim.fn.fnamemodify(buf_path, ":h")
        vim.cmd("GoBuild" .. package)
      end,
      desc = "Go build current package",
    },
    {
      "<leader>cb",
      function()
        choose_go_program(function(choice)
          vim.cmd("GoBuild" .. choice)
        end)
      end,
      desc = "Go build a package",
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
