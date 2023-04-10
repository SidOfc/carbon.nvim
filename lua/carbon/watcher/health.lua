local util = require('carbon.util')
local watcher = require('carbon.watcher')
local health = {}

function health.check()
  health.report_listeners()
  health.report_events()
end

function health.report_events()
  vim.health.report_start('events')

  local names = vim.tbl_keys(watcher.events)

  table.sort(names, function(a, b)
    return string.lower(a) < string.lower(b)
  end)

  for _, name in ipairs(names) do
    local callback_count = #vim.tbl_keys(watcher.events[name] or {})
    local reporter = callback_count == 0 and 'report_warn' or 'report_ok'

    vim.health[reporter](
      string.format(
        '%d %s attached to %s',
        callback_count,
        callback_count == 1 and 'handler' or 'handlers',
        name
      )
    )
  end
end

function health.report_listeners()
  vim.health.report_start('listeners')

  local paths = vim.tbl_keys(watcher.listeners)

  table.sort(paths, function(a, b)
    local a_is_directory = util.is_directory(a)
    local b_is_directory = util.is_directory(b)

    if a_is_directory and b_is_directory then
      return string.lower(a) < string.lower(b)
    elseif a_is_directory then
      return true
    elseif b_is_directory then
      return false
    end

    return string.lower(a) < string.lower(b)
  end)

  for _, path in ipairs(paths) do
    vim.health.report_ok(path)
  end
end

return health
