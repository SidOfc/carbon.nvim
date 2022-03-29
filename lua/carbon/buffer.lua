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
  sync_timer = -1,
  resync_paths = {},
}

function buffer.process_event(_, path)
  vim.fn.timer_stop(data.sync_timer)

  data.resync_paths[path] = true

  data.sync_timer = vim.fn.timer_start(settings.sync_delay, function()
    buffer.synchronize()

    data.resync_paths = {}
  end)
end

function buffer.is_loaded()
  return vim.api.nvim_buf_is_loaded(data.handle)
end

function buffer.is_hidden()
  local properties = vim.fn.getbufinfo(data.handle)[1]

  return properties and properties.hidden == 1
end

function buffer.handle()
  if buffer.is_loaded() then
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
        local keys = mapping

        if type(keys) == 'string' then
          keys = { keys }
        end

        for _, key in ipairs(keys) do
          util.map(
            key,
            util.plug(action),
            { buffer = data.handle, nowait = true, silent = true }
          )
        end
      end
    end
  end

  util.map('<cr>', '<esc>:lua require("carbon.buffer").create_confirm()<cr>', {
    buffer = data.handle,
    nowait = true,
    silent = true,
    noremap = true,
    mode = 'i',
  })
  util.map('<esc>', '<esc>:lua require("carbon.buffer").create_cancel()<cr>', {
    buffer = data.handle,
    nowait = true,
    silent = true,
    noremap = true,
    mode = 'i',
  })

  return data.handle
end

function buffer.show()
  vim.api.nvim_win_set_buf(0, buffer.handle())
  vim.api.nvim_win_set_option(0, 'spell', false)
  buffer.render()
end

function buffer.render()
  if not buffer.is_loaded() or buffer.is_hidden() then
    return
  end

  local handle = buffer.handle()
  local lines = {}
  local hls = {}

  for lnum, line_data in ipairs(buffer.lines()) do
    lines[#lines + 1] = line_data.line

    for _, hl in ipairs(line_data.highlights) do
      hls[#hls + 1] = { hl[1], lnum - 1, hl[2], hl[3] }
    end
  end

  vim.api.nvim_buf_clear_namespace(handle, data.namespace, 0, -1)
  buffer.modifiable(function()
    vim.api.nvim_buf_set_lines(handle, 0, -1, 1, lines)
  end)

  for _, hl in ipairs(hls) do
    vim.api.nvim_buf_add_highlight(handle, data.namespace, unpack(hl))
  end
end

function buffer.modifiable(callback)
  local handle = buffer.handle()

  vim.api.nvim_buf_set_option(handle, 'modifiable', true)

  local result = callback()

  vim.api.nvim_buf_set_option(handle, 'modifiable', false)

  return result
end

function buffer.cursor()
  return buffer.lines()[vim.fn.line('.')]
end

function buffer.lines(input_target, lines, depth)
  lines = lines or {}
  depth = depth or 0
  local target = input_target or data.root
  local expand_indicator = ' '
  local collapse_indicator = ' '

  if type(settings.indicators) == 'table' then
    expand_indicator = settings.indicators.expand or expand_indicator
    collapse_indicator = settings.indicators.collapse or collapse_indicator
  end

  if not input_target and #lines == 0 then
    lines[#lines + 1] = {
      lnum = 1,
      depth = depth,
      entry = data.root,
      line = data.root.name .. '/',
      highlights = { { 'CarbonDir', 0, -1 } },
      path = {},
    }
  end

  for _, child in ipairs(target:children()) do
    local tmp = child
    local hls = {}
    local path = {}
    local lnum = 1 + #lines
    local indent = string.rep('  ', depth)
    local is_empty = true
    local indicator = ' '
    local path_suffix = ''

    if settings.compress then
      while
        tmp.is_directory
        and #tmp:children() == 1
        and tmp:is_compressible()
      do
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
      vim.tbl_map(function(parent)
        return parent.name
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
      lnum = lnum,
      depth = depth,
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
  local paths = vim.tbl_keys(data.resync_paths)

  table.sort(paths, function(a, b)
    return #a < #b
  end)

  for idx = #paths, 1, -1 do
    local path = paths[idx]
    local found_path = util.tbl_find(paths, function(other)
      return path ~= other and vim.startswith(path, other)
    end)

    if not found_path then
      local found_entry = entry.find(path)

      if found_entry then
        found_entry:synchronize()
      elseif path == data.root.path then
        data.root:synchronize()
      end
    end
  end

  buffer.render()
end

function buffer.up(count)
  local rerender = false
  local remaining = count or vim.v.count1

  while remaining > 0 do
    remaining = remaining - 1
    local new_root = entry.new(vim.fn.fnamemodify(data.root.path, ':h'))

    if new_root.path ~= data.root.path then
      new_root:set_children(vim.tbl_map(function(child)
        if child.path == data.root.path then
          child:set_open(true)
          child:set_children(data.root:children())
        end

        return child
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

function buffer.entry_line(target_entry)
  for _, current_line in ipairs(buffer.lines()) do
    if current_line.entry.path == target_entry.path then
      return current_line
    end

    for _, parent in ipairs(current_line.path) do
      if parent.path == target_entry.path then
        return current_line
      end
    end
  end
end

function buffer.create()
  local line = buffer.cursor()
  local handle = buffer.handle()
  local line_entry = line.entry
  local line_lnum = line.lnum
  local line_depth = line.depth + 2

  if not line_entry.is_directory then
    line_entry = line.path and line.path[#line.path] or line_entry.parent
  end

  data.line_entry = line_entry
  data.prev_open = line_entry:is_open()
  data.prev_compressible = line_entry:is_compressible()

  line_entry:set_open(true)
  line_entry:set_compressible(false)

  if line_entry ~= line.entry then
    line = buffer.entry_line(line_entry)
    line_lnum = line.lnum
    line_depth = line.depth + 2
  end

  if line_entry.path == data.root.path then
    line_depth = 1
  end

  local edit_lnum = line_lnum + #buffer.lines(line_entry)
  local edit_indent = string.rep('  ', line_depth)

  buffer.render()
  buffer.modifiable(function()
    vim.api.nvim_buf_set_lines(handle, edit_lnum, edit_lnum, 1, { edit_indent })
  end)

  data.cancel_jump = { lnum = line.lnum, col = 1 }
  data.cursor_bounds = { lnum = edit_lnum + 1, col = #edit_indent }

  vim.fn.cursor(edit_lnum + 1, #edit_indent)
  vim.api.nvim_buf_set_option(handle, 'modifiable', true)
  vim.cmd('startinsert!')
end

function buffer.create_confirm()
  local text = vim.fn.trim(vim.fn.getline('.'))
  local name = vim.fn.fnamemodify(text, ':t')
  local parent_dir = data.line_entry.path
    .. '/'
    .. vim.fn.trim(vim.fn.fnamemodify(text, ':h'), './')

  vim.fn.mkdir(parent_dir, 'p')
  vim.fn.writefile({}, parent_dir .. '/' .. name)
  data.line_entry:synchronize()
  buffer.create_reset()
end

function buffer.create_cancel()
  data.line_entry:set_open(data.prev_open)
  buffer.create_reset()
  buffer.render()
end

function buffer.create_reset()
  local handle = buffer.handle()
  local lnum = vim.fn.line('.')

  vim.api.nvim_buf_set_lines(handle, lnum - 1, lnum, 1, {})
  vim.api.nvim_buf_set_option(handle, 'modifiable', false)
  vim.api.nvim_buf_set_option(handle, 'modified', false)

  vim.fn.cursor(data.cancel_jump.lnum, data.cancel_jump.col)
  data.line_entry:set_compressible(data.prev_compressible)

  data.prev_open = nil
  data.line_entry = nil
  data.cancel_jump = nil
  data.cursor_bounds = nil
  data.prev_compressible = nil
end

function buffer.ensure_cursor_bounds()
  if data.cursor_bounds then
    vim.fn.cursor(
      data.cursor_bounds.lnum,
      math.max(data.cursor_bounds.col, vim.fn.col('.'))
    )
  end
end

return buffer
