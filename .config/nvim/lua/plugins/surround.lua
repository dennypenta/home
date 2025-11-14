return {
  "nvim-mini/mini.surround",
  pin = true,
  opts = {
    -- No need to copy this inside `setup()`. Will be used automatically.
    mappings = {
      add = "sa", -- Add surrounding in Normal and Visual modes
      delete = "sd", -- Delete surrounding
      find = "sf", -- Find surrounding (to the right)
      find_left = "sF", -- Find surrounding (to the left)
      highlight = "sh", -- Highlight surrounding
      replace = "sr", -- Replace surrounding

      suffix_last = "l", -- Suffix to search with "prev" method
      suffix_next = "n", -- Suffix to search with "next" method
    },

    -- Number of lines within which surrounding is searched
    n_lines = 40,
  },
}
