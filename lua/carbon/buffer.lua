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
        path[#path + 1] = tmp
        tmp = tmp:children()[1]
      end
    end

    if tmp.is_directory then
      is_empty = #tmp:children() == 0
      path_suffix = '/'

      if not is_empty and tmp.is_open then
        indicator = settings.indicators.collapse
      elseif not is_empty then
        indicator = settings.indicators.expand
      end
    end

    local full_path = tmp.name .. path_suffix
    local indent_end = #indent
    local path_start = indent_end + #indicator + 1
    local file_group = 'CarbonFile'
    local dir_path = table.concat(
      vim.tbl_map(function(entry)
        return entry.name
      end, path),
      '/'
    )

    if path[1] then
      full_path = dir_path .. '/' .. full_path
    end

    if tmp.is_executable then
      file_group = 'CarbonExe'
    elseif tmp.is_symlink == 1 then
      file_group = 'CarbonSymlink'
    end

    if not is_empty then
      hls[#hls + 1] = { 'CarbonIndicator', indent_end, path_start - 1 }
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
      path = path,
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

function buffer.up(count)
  local parent = entry:new(
    vim.fn.fnamemodify(
      buffer.data.root.path,
      string.rep(':h', count or vim.v.count1)
    )
  )

  if parent.path ~= buffer.data.root.path then
    local children = vim.tbl_map(function(entry)
      if entry.path == buffer.data.root.path then
        return buffer.data.root
      end

      return entry
    end, parent:get_children())

    entry.data.children[parent.path] = children
    buffer.data.root.parent = parent
    buffer.data.root.is_open = true
    buffer.data.root = parent

    return true
  end
end

function buffer.down(count)
  local lnum = vim.fn.line('.')
  local data = buffer.lines()[lnum]
  local entry = data.path[count or vim.v.count1] or data.entry

  if not entry.is_directory then
    entry = entry.parent
  end

  if entry.path ~= buffer.data.root.path then
    buffer.data.root = entry

    entry:clean(buffer.data.root.path)

    return true
  end
end

function buffer.cd()
  local new_root = entry:new(vim.v.event.cwd)

  if util.is_parent_of(new_root.path, buffer.data.root.path) then
    local new_depth = util.path_depth(new_root.path)
    local current_depth = util.path_depth(buffer.data.root.path)

    buffer.up(current_depth - new_depth)

    return true
  else
    buffer.data.root = buffer.data.root:find_child(new_root.path) or new_root

    entry:clean(buffer.data.root.path)

    return true
  end
end

return buffer
