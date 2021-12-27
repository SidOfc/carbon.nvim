local util = require('carbon.util')
local entry = require('carbon.entry')
local watcher = require('carbon.watcher')
local settings = require('carbon.settings')
local buffer = {
  data = {
    root = entry:new(vim.fn.getcwd()),
    current = -1,
    namespace = vim.api.nvim_create_namespace('carbon'),
    status_timer = -1,
  },
}

watcher.register(buffer.data.root.path)
watcher.on('rename', function(path, filename)
  vim.fn.timer_stop(buffer.data.status_timer)

  buffer.data.status_timer = vim.fn.timer_start(
    settings.sync_delay,
    buffer.synchronize
  )
end)

function buffer.current()
  if vim.api.nvim_buf_is_loaded(buffer.data.current) then
    return buffer.data.current
  end

  buffer.data.current = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_name(buffer.data.current, 'carbon')
  vim.api.nvim_buf_set_option(buffer.data.current, 'swapfile', false)
  vim.api.nvim_buf_set_option(buffer.data.current, 'filetype', 'carbon')
  vim.api.nvim_buf_set_option(buffer.data.current, 'bufhidden', 'hide')
  vim.api.nvim_buf_set_option(buffer.data.current, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buffer.data.current, 'modifiable', false)

  if type(settings.actions) == 'table' then
    for action, mapping in pairs(settings.actions) do
      if mapping then
        util.map({
          mapping,
          util.plug_name(action),
          buffer = buffer.data.current,
          silent = true,
        })
      end
    end
  end

  return buffer.data.current
end

function buffer.show()
  vim.api.nvim_win_set_buf(0, buffer.current())
  buffer.render()
end

function buffer.render()
  local current = buffer.current()
  local lines = {}
  local hls = {}

  for lnum, data in ipairs(buffer.lines()) do
    lines[#lines + 1] = data.line

    for _, hl in ipairs(data.highlights) do
      hls[#hls + 1] = { hl[1], lnum - 1, hl[2], hl[3] }
    end
  end

  vim.api.nvim_buf_set_option(current, 'modifiable', true)
  vim.api.nvim_buf_set_lines(current, 0, -1, 1, lines)
  vim.api.nvim_buf_set_option(current, 'modifiable', false)
  vim.api.nvim_buf_clear_namespace(current, buffer.data.namespace, 0, -1)

  for _, hl in ipairs(hls) do
    vim.api.nvim_buf_add_highlight(current, buffer.data.namespace, unpack(hl))
  end
end

function buffer.entry()
  return buffer.lines()[vim.fn.line('.')].entry
end

function buffer.lines(entry, lines, depth)
  entry = entry or buffer.data.root
  lines = lines or {}
  depth = depth or 0

  for _, child in ipairs(entry:children()) do
    local tmp = child
    local hls = {}
    local path = {}
    local indent = string.rep('  ', depth)
    local is_empty = true
    local indicator = ' '
    local path_suffix = ''

    if settings.compress then
      while tmp.is_directory and #tmp:children() == 1 do
        path[#path + 1] = tmp.name
        tmp = tmp:children()[1]
      end
    end

    if tmp.is_selected or tmp.is_partial then
      indicator = settings.indicators.selected
    end

    if tmp.is_directory then
      is_empty = #tmp:children() == 0
      path_suffix = '/'

      if not is_empty and tmp.is_open then
        indicator = settings.indicators.expanded
      elseif not is_empty then
        indicator = settings.indicators.collapsed
      end
    end

    local dir_path = table.concat(path, '/')
    local full_path = tmp.name .. path_suffix
    local indent_end = #indent
    local path_start = indent_end + #indicator + 1

    if path[1] then
      full_path = dir_path .. '/' .. full_path
    end

    if not is_empty or tmp.is_selected or tmp.is_partial then
      local group = 'CarbonIndicator'

      if tmp.is_selected then
        group = 'CarbonIndicatorSelected'
      elseif tmp.is_partial then
        group = 'CarbonIndicatorPartial'
      end

      hls[#hls + 1] = { group, indent_end, path_start - 1 }
    end

    local file_group = 'CarbonFile'
    if tmp.is_executable then
      file_group = 'CarbonExe'
    elseif tmp.is_symlink == 1 then
      file_group = 'CarbonSymlink'
    end

    if tmp.is_symlink == 2 then
      hls[#hls + 1] = { 'CarbonBrokenSymlink', path_start, -1 }
    elseif tmp.is_directory then
      hls[#hls + 1] = { 'CarbonDir', path_start, -1 }
    elseif path[1] then
      local dir_end = path_start + #dir_path + 1

      hls[#hls + 1] = { 'CarbonDir', path_start, dir_end }
      hls[#hls + 1] = { file_group, dir_end, -1 }
    else
      hls[#hls + 1] = { file_group, path_start, -1 }
    end

    lines[#lines + 1] = {
      entry = tmp,
      line = indent .. indicator .. ' ' .. full_path,
      highlights = hls,
    }

    if tmp.is_directory and tmp.is_open then
      buffer.lines(tmp, lines, depth + 1)
    end
  end

  return lines
end

function buffer.synchronize()
  buffer.data.root:synchronize()
  buffer.render()
end

return buffer
