-- *.env.* files are kinda sh
vim.filetype.add({
  pattern = {
    ["%.env%.[%w_.-]+"] = "sh",
  },
})

vim.filetype.add({
  extension = {
    mdx = "markdown",
  },
})
