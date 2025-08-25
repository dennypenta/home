return {
  "karb94/neoscroll.nvim",
  pin = true,
  -- TODO: remove or fix pkg/scroll
  cond = false,
  config = function()
    require('neoscroll').setup({
      duration_multiplier = 0.5,
    })
  end,
}
