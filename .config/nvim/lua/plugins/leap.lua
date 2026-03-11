return {
  url = "https://codeberg.org/andyg/leap.nvim.git",
  pin = true,
  config = function()
    local leap = require("leap")
    leap.add_default_mappings()
    leap.opts.case_sensitive = true
  end,
}
