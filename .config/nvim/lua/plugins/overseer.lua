return {
  "stevearc/overseer.nvim",
  opts = {
    component_aliases = {
      default_neotest = {
        "on_output_summarize",
        "on_exit_set_status",
        "on_complete_notify",
        "on_complete_dispose",
      },
    },
  },
}
