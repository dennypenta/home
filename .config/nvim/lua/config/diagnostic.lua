local signs = require("pkg.icons").Diagnostic

vim.diagnostic.config({
  severity_sort = true,
  virtual_text = {
    prefix = function(diagnostic)
      if diagnostic.severity == vim.diagnostic.severity.ERROR then
        return signs.Error
      elseif diagnostic.severity == vim.diagnostic.severity.WARN then
        return signs.Warn
      elseif diagnostic.severity == vim.diagnostic.severity.INFO then
        return signs.Info
      else
        return signs.Hint
      end
    end,
  },
})
