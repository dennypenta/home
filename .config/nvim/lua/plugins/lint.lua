local root_linters = {
  go = "golangci_root",
}

function table.copy(t)
  local u = {}
  for k, v in pairs(t) do
    u[k] = v
  end
  setmetatable(u, getmetatable(t))
  return u
end

local qlist = {}

local function make_golangcilint_root(original)
  local golangci_root = table.copy(original)
  golangci_root.args[#golangci_root.args] = function()
    return vim.uv.cwd() .. "/..."
  end
  golangci_root.parser = function(output, bufnr, cwd)
    if output == "" then
      return {}
    end
    local decoded = vim.json.decode(output)
    if decoded["Issues"] == nil or type(decoded["Issues"]) == "userdata" then
      return {}
    end

    local q_severities = {
      error = "E",
      warning = "W",
      refactor = "I",
      convention = "H",
    }
    local severities = {
      E = vim.diagnostic.severity.ERROR,
      W = vim.diagnostic.severity.WARN,
      I = vim.diagnostic.severity.INFO,
      H = vim.diagnostic.severity.HINT,
    }

    local diagnostics = {}
    local other_ds = {}
    qlist = {}
    for _, item in ipairs(decoded["Issues"]) do
      local curfile = vim.api.nvim_buf_get_name(bufnr)
      local curfile_abs = vim.fn.fnamemodify(curfile, ":p")
      local curfile_norm = vim.fs.normalize(curfile_abs)

      local lintedfile = cwd .. "/" .. item.Pos.Filename
      local lintedfile_abs = vim.fn.fnamemodify(lintedfile, ":p")
      local lintedfile_norm = vim.fs.normalize(lintedfile_abs)

      local qitem = {
        filename = lintedfile_norm,
        lnum = item.Pos.Line > 0 and item.Pos.Line - 1 or 0,
        col = item.Pos.Column > 0 and item.Pos.Column - 1 or 0,
        end_lnum = item.Pos.Line > 0 and item.Pos.Line - 1 or 0,
        end_col = item.Pos.Column > 0 and item.Pos.Column - 1 or 0,
        source = item.FromLinter,
        text = item.Text,
        type = q_severities[item.Severity] or "W",
      }
      local buf = vim.fn.bufnr(item.Pos.Filename)
      if curfile_norm == item.Pos.Filename or curfile_norm == lintedfile_norm then
        -- only publish if those are the current file diagnostics
        table.insert(diagnostics, {
          lnum = qitem.lnum,
          col = qitem.col,
          end_lnum = qitem.end_lnum,
          end_col = qitem.end_col,
          severity = severities[qitem.type] or vim.diagnostic.severity.WARN,
          source = qitem.source,
          message = qitem.text,
        })
      elseif buf > -1 then
        if other_ds[buf] == nil then
          other_ds[buf] = {}
        end
        table.insert(other_ds[buf], {
          lnum = qitem.lnum,
          col = qitem.col,
          end_lnum = qitem.end_lnum,
          end_col = qitem.end_col,
          severity = severities[qitem.type] or vim.diagnostic.severity.WARN,
          source = qitem.source,
          message = qitem.text,
        })
      end
      -- but collect everything to qlist
      table.insert(qlist, qitem)
    end

    for buf, ds in pairs(other_ds) do
      vim.diagnostic.set(require("lint").get_namespace("golangcilint"), buf, ds)
    end
    vim.fn.setqflist({}, "r", { title = "Go Lint Errors", items = qlist })
    vim.api.nvim_command("copen")

    -- populate diagnostic on opening a buffer
    vim.api.nvim_create_autocmd("BufReadPost", {
      group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
      callback = function(args)
        local ds = {}
        for _, item in pairs(qlist) do
          if item.filename == args.file then
            table.insert(ds, {
              lnum = item.lnum,
              col = item.col,
              end_lnum = item.end_lnum,
              end_col = item.end_col,
              severity = severities[item.type] or vim.diagnostic.severity.WARN,
              source = item.source,
              message = item.text,
            })
          end
        end
        vim.diagnostic.set(require("lint").get_namespace("golangcilint"), args.buf, ds)
      end,
    })

    return diagnostics
  end

  return golangci_root
end

return {
  "mfussenegger/nvim-lint",
  pin = true,
  lazy = false,
  config = function()
    local lint = require("lint")
    lint.linters_by_ft = {
      go = { "golangcilint" },
      zig = { "zlint", "zig" },
    }

    lint.linters.golangci_root = make_golangcilint_root(lint.linters.golangcilint)

    local pattern = "^::(%w+) file=([^,]+),line=(%d+),col=(%d+),title=([^:]+)::(.+)$"
    local groups = { "severity", "file", "lnum", "col", "code", "message" }
    local severity_map = {
      ["error"] = vim.diagnostic.severity.ERROR,
      ["warning"] = vim.diagnostic.severity.WARN,
    }

    lint.linters.zlint = {
      name = "zlint",
      cmd = "zlint",
      args = { "--format", "github" },
      stdin = false,
      append_fname = false,
      stream = "both",
      ignore_exitcode = true,
      parser = require("lint.parser").from_pattern(pattern, groups, severity_map),
    }

    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      callback = function()
        lint.try_lint()
      end,
    })
  end,
  keys = {
    {
      -- TODO: display when it's running: https://github.com/mfussenegger/nvim-lint?tab=readme-ov-file#get-the-current-running-linters-for-your-buffer
      "<leader>cl",
      function()
        local linter = root_linters[vim.bo.filetype]
        require("lint").try_lint(linter)
      end,
      desc = "Lint",
    },
  },
}
