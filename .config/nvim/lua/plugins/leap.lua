return {
  url = "https://codeberg.org/andyg/leap.nvim.git",
  pin = true,
  enabled = false,
  config = function()
    local leap = require("leap")
    leap.add_default_mappings()
    leap.opts.case_sensitive = true
  end,
}
