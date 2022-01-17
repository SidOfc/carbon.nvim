local util = require('carbon.util')
local entry = require('carbon.entry')
local settings = require('carbon.settings')
local buffer = {}
local open_cwd = vim.fn.getcwd()
local data = {
  root = entry.new(open_cwd),
  handle = -1,
  open_cwd = open_cwd,
  namespace = vim.api.nvim_create_namespace('carbon'),
  status_timer = -1,
}

function buffer.watch(path, filename)
  vim.fn.timer_stop(data.status_timer)

  data.status_timer = vim.fn.timer_start(
    settings.sync_delay,
    buffer.synchronize
  )
end

function buffer.handle()
  if vim.api.nvim_buf_is_loaded(data.handle) then
    return data.handle
  end

  data.handle = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_name(data.handle, 'carbon')
  vim.api.nvim_buf_set_option(data.handle, 'swapfile', false)
  vim.api.nvim_buf_set_option(data.handle, 'filetype', 'carbon')
  vim.api.nvim_buf_set_option(data.handle, 'bufhidden', 'hide')
  vim.api.nvim_buf_set_option(data.handle, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(data.handle, 'modifiable', false)

  if type(settings.actions) == 'table' then
    for action, mapping in pairs(settings.actions) do
      if mapping then
        util.map(
          mapping,
          util.plug(action),
          { buffer = data.handle, nowait = true, silent = true }
        )
      end
    end
  end

  return data.handle
end

function buffer.show()
  vim.api.nvim_win_set_buf(0, buffer.handle())
  buffer.render()
end

function buffer.render()
  local handle = buffer.handle()
  local lines = {}
  local hls = {}

  for lnum, data in ipairs(buffer.lines()) do
    lines[#lines + 1] = data.line

    for _, hl in ipairs(data.highlights) do
      hls[#hls + 1] = { hl[1], lnum - 1, hl[2], hl[3] }
    end
  end

  vim.api.nvim_buf_set_option(handle, 'modifiable', true)
  vim.api.nvim_buf_set_lines(handle, 0, -1, 1, lines)
  vim.api.nvim_buf_set_option(handle, 'modifiable', false)
  vim.api.nvim_buf_clear_namespace(handle, data.namespace, 0, -1)

  for _, hl in ipairs(hls) do
    vim.api.nvim_buf_add_highlight(handle, data.namespace, unpack(hl))
  end
end

function buffer.cursor()
  return buffer.lines()[vim.fn.line('.')]
end

function buffer.lines(entry, lines, depth)
  entry = entry or data.root
  lines = lines or {}
  depth = depth or 0
  local expand_indicator = ' '
  local collapse_indicator = ' '

  if type(settings.indicators) == 'table' then
    expand_indicator = settings.indicators.expand or expand_indicator
    collapse_indicator = settings.indicators.collapse or collapse_indicator
  end

  if #lines == 0 then
    lines[#lines + 1] = {
      entry = data.root,
      line = data.root.name .. '/',
      highlights = { { 'CarbonDir', 0, -1 } },
      path = {},
    }
  end

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

      if not is_empty and tmp:is_open() then
        indicator = collapse_indicator
      elseif not is_empty then
        indicator = expand_indicator
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
    elseif tmp.is_symlink == 2 then
      file_group = 'CarbonBrokenSymlink'
    end

    if not is_empty then
      hls[#hls + 1] = { 'CarbonIndicator', indent_end, path_start - 1 }
    end

    if tmp.is_directory then
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

    if tmp.is_directory and tmp:is_open() then
      buffer.lines(tmp, lines, depth + 1)
    end
  end

  return lines
end

function buffer.synchronize()
  data.root:synchronize()
  buffer.render()
end

function buffer.up(count)
  local rerender = false
  local remaining = count or vim.v.count1

  while remaining > 0 do
    remaining = remaining - 1
    local new_root = entry.new(vim.fn.fnamemodify(data.root.path, ':h'))

    if new_root.path ~= data.root.path then
      new_root:set_children(vim.tbl_map(function(entry)
        if entry.path == data.root.path then
          data.root:set_open(true)
          data.root.parent = new_root

          return data.root
        end

        return entry
      end, new_root:get_children()))

      rerender = true
      data.root = new_root
    end
  end

  return rerender
end

function buffer.down(count)
  local cursor = buffer.cursor()
  local new_root = cursor.path[count or vim.v.count1] or cursor.entry

  if not new_root.is_directory then
    new_root = new_root.parent
  end

  if new_root.path ~= data.root.path then
    data.root:set_open(true)

    data.root = new_root

    entry.clean(data.root.path)

    return true
  end
end

function buffer.reset()
  return buffer.cd(open_cwd)
end

function buffer.cd(path)
  local new_root = entry.new(path)

  if new_root.path == data.root.path then
    return false
  elseif vim.startswith(data.root.path, new_root.path) then
    local new_depth = select(2, string.gsub(new_root.path, '/', ''))
    local current_depth = select(2, string.gsub(data.root.path, '/', ''))

    if current_depth - new_depth > 0 then
      buffer.up(current_depth - new_depth)

      return true
    end
  else
    data.root = entry.find(new_root.path) or new_root

    entry.clean(data.root.path)

    return true
  end
end

return buffer
