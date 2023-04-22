local util = require('carbon.util')
local view = require('carbon.view')
local watcher = require('carbon.watcher')
local health = {}

local function sort_names(a, b)
  return string.lower(a) < string.lower(b)
end

local function sort_paths(a, b)
  local a_is_directory = util.is_directory(a)
  local b_is_directory = util.is_directory(b)

  if a_is_directory and b_is_directory then
    return sort_names(a, b)
  elseif a_is_directory then
    return true
  elseif b_is_directory then
    return false
  end

  return sort_names(a, b)
end

function health.check()
  health.report_views()
  health.report_listeners()
  health.report_events()
end

function health.report_views()
  vim.health.report_start('view::active')

  local view_roots = vim.tbl_map(function(item)
    return item.root
  end, view.items)

  table.sort(view_roots)

  for _, root in ipairs(view_roots) do
    vim.health.report_info(root.path)
  end
end

function health.report_events()
  vim.health.report_start('watcher::events')

  local names = vim.tbl_keys(watcher.events)

  table.sort(names, sort_names)

  for _, name in ipairs(names) do
    local callback_count = #vim.tbl_keys(watcher.events[name] or {})
    local reporter = callback_count == 0 and 'report_warn' or 'report_info'

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
  vim.health.report_start('watcher::listeners')

  local paths = vim.tbl_keys(watcher.listeners)

  table.sort(paths, sort_paths)

  for _, path in ipairs(paths) do
    vim.health.report_info(path)
  end
end

return health
