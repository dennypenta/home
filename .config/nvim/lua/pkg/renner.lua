local M = {}

--- Run a task and execute callback on success
--- @param opts table { task: Task, on_success: function, on_failure?: function, cleanup?: boolean, status_pattern?: string }
function M.run_task_then(opts)
  local task = opts.task
  local on_success = opts.on_success
  local on_failure = opts.on_failure
  local cleanup = opts.cleanup ~= false -- default true
  local status_pattern = opts.status_pattern or "^STATUS:(%d+)$"

  if not task or not task.command then
    vim.notify("Invalid task: missing command field", vim.log.levels.ERROR)
    return
  end

  if not on_success then
    vim.notify("Invalid opts: missing on_success callback", vim.log.levels.ERROR)
    return
  end

  -- Create modified task with status check appended
  local modified_task = vim.deepcopy(task)
  modified_task.command = modified_task.command .. "; echo STATUS:$?"

  -- Get buildFunc from compile plugin
  local buildFunc = require("plugins.compile").buildFunc

  -- Run task with status checking
  buildFunc(modified_task, status_pattern, function(status)
    if status == "0" then
      -- Success path
      if cleanup then
        local compile = require("compile")
        compile.destroy()
      end
      on_success()
    else
      -- Failure path
      if on_failure then
        on_failure(status)
      end
    end
  end)
end

return M
