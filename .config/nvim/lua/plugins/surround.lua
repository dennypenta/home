local mappings = {
  add = "sa", -- add surrounding in normal and visual modes
  delete = "sd", -- delete surrounding
  find = "sf", -- find surrounding (to the right)
  find_left = "sf", -- find surrounding (to the left)
  highlight = "sh", -- highlight surrounding
  replace = "sr", -- replace surrounding
  update_n_lines = "sn", -- update `n_lines`

  suffix_last = "l", -- suffix to search with "prev" method
  suffix_next = "n", -- suffix to search with "next" method
}

return {
  "echasnovski/mini.surround",
  version = "*",
  opts = {
    mappings = mappings,
  },
  keys = function(_, keys)
    return {
      { mappings.add, desc = "Add Surrounding", mode = { "n", "v" } },
      { mappings.delete, desc = "Delete Surrounding" },
      { mappings.find, desc = "Find Right Surrounding" },
      { mappings.find_left, desc = "Find Left Surrounding" },
      { mappings.highlight, desc = "Highlight Surrounding" },
      { mappings.replace, desc = "Replace Surrounding" },
      { mappings.update_n_lines, desc = "Update `MiniSurround.config.n_lines`" },
    }
  end,
}
