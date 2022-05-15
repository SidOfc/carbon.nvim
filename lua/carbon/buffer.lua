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

  local mappings = {
    { 'i', '<nop>' },
    { '<cr>', buffer.create_confirm, { mode = 'i', rhs_prefix = '<esc>' } },
    { '<esc>', buffer.create_cancel, { mode = 'i', rhs_prefix = '<esc>' } },
  }

  for action, mapping in pairs(settings.actions or {}) do
    mapping = type(mapping) == 'string' and { mapping } or mapping or {}

    for _, key in ipairs(mapping) do
      mappings[#mappings + 1] = { key, util.plug(action) }
    end
  end

  data.handle = util.create_scratch_buf({
    name = 'carbon',
    filetype = 'carbon',
    modifiable = false,
    modified = false,
    bufhidden = 'hide',
    mappings = mappings,
    autocmds = {
      BufEnter = buffer.process_enter,
      BufHidden = buffer.process_hidden,
    },
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

  local lines = {}
  local hls = {}

  for lnum, line_data in ipairs(buffer.lines()) do
    lines[#lines + 1] = line_data.line

    for _, hl in ipairs(line_data.highlights) do
      hls[#hls + 1] = { hl[1], lnum - 1, hl[2], hl[3] }
    end
  end

  buffer.clear_namespace(0, -1)
  buffer.set_lines(0, -1, 1, lines)

  for _, hl in ipairs(hls) do
    buffer.add_highlight(unpack(hl))
  end
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
      depth = -1,
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
      rerender = true

      buffer.set_root(new_root)
      new_root:set_children(vim.tbl_map(function(child)
        if child.path == data.root.path then
          child:set_open(true)
          child:set_children(data.root:children())
        end

        return child
      end, new_root:get_children()))
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
    buffer.set_root(new_root)

    return true
  end
end

function buffer.set_root(target)
  if type(target) == 'string' then
    target = entry.new(target)
  end

  data.root = target
  entry.clean(data.root.path)

  if settings.sync_pwd then
    vim.fn.chdir(data.root.path)
  end

  return data.root
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
    buffer.set_root(entry.find(new_root.path) or new_root)

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

function buffer.delete()
  local line = buffer.cursor()
  local targets = util.tbl_concat(line.path, { line.entry })

  local lnum_idx = line.lnum - 1
  local count = vim.v.count == 0 and #targets or vim.v.count1
  local path_idx = math.min(count, #targets)
  local target = targets[path_idx]
  local highlight = { 'CarbonFile', 2 + line.depth * 2, lnum_idx }

  if targets[path_idx].path == data.root.path then
    return
  end

  if target.is_directory then
    highlight[1] = 'CarbonDir'
  end

  for idx = 1, path_idx - 1 do
    highlight[2] = highlight[2] + #line.path[idx].name + 1
  end

  buffer.clear_extmarks({ lnum_idx, highlight[2] }, { lnum_idx, -1 }, {})
  buffer.add_highlight('CarbonDanger', lnum_idx, highlight[2], -1)
  util.confirm_action({
    row = line.lnum,
    col = highlight[2],
    highlight = 'CarbonDanger',
    order = { 'delete', 'cancel' },
    actions = {
      delete = function()
        local result = vim.fn.delete(
          target.path,
          target.is_directory and 'rf' or ''
        )

        if result == -1 then
          vim.api.nvim_err_writeln('Failed to delete: "' .. target.path .. '"')
        else
          target.parent:synchronize()
          buffer.cancel_synchronization()
        end
      end,

      cancel = function()
        buffer.clear_extmarks({ lnum_idx, 0 }, { lnum_idx, -1 }, {})

        for _, lhl in ipairs(line.highlights) do
          buffer.add_highlight(lhl[1], lnum_idx, lhl[2], lhl[3])
        end

        buffer.render()
      end,
    },
  })
end

function buffer.create()
  local line = buffer.cursor()
  local handle = buffer.handle()
  local line_entry = line.entry
  local line_lnum = line.lnum
  local line_depth = line.depth + 2

  if not line_entry.is_directory then
    line_entry = line.path[#line.path] or line_entry.parent
  end

  if vim.v.count > 0 and #line.path > 0 then
    line_entry = line.path[math.min(vim.v.count, #line.path)]
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

  local edit_lnum = line_lnum + #buffer.lines(line_entry)
  local edit_indent = string.rep('  ', line_depth)

  buffer.render()
  buffer.set_lines(edit_lnum, edit_lnum, 1, { edit_indent })

  data.reset_jump = { lnum = line.lnum, col = 1 }
  data.cursor_bounds = { lnum = edit_lnum + 1, col = #edit_indent + 1 }
  data.insert_move_autocmd = util.autocmd(
    'CursorMovedI',
    buffer.process_insert_move,
    { buffer = handle }
  )

  vim.fn.cursor(edit_lnum + 1, #edit_indent)
  vim.api.nvim_buf_set_option(handle, 'modifiable', true)
  vim.cmd('startinsert!')
end

function buffer.create_confirm()
  local text = vim.fn.trim(vim.fn.getline('.'))
  local name = vim.fn.fnamemodify(text, ':t')
  local parent_directory = data.line_entry.path
    .. '/'
    .. vim.fn.trim(vim.fn.fnamemodify(text, ':h'), './', 2)

  vim.fn.mkdir(parent_directory, 'p')

  if name ~= '' then
    vim.fn.writefile({}, parent_directory .. '/' .. name)
  end

  data.line_entry:synchronize()
  buffer.cancel_synchronization()
  buffer.create_reset()
end

function buffer.create_cancel()
  data.line_entry:set_open(data.prev_open)
  buffer.create_reset()
end

function buffer.create_reset()
  local handle = buffer.handle()
  local lnum = vim.fn.line('.')

  vim.api.nvim_del_autocmd(data.insert_move_autocmd)
  vim.api.nvim_buf_set_lines(handle, lnum - 1, lnum, 1, {})
  vim.api.nvim_buf_set_option(handle, 'modifiable', false)
  vim.api.nvim_buf_set_option(handle, 'modified', false)
  vim.fn.cursor(data.reset_jump.lnum, data.reset_jump.col)
  data.line_entry:set_compressible(data.prev_compressible)

  data.prev_open = nil
  data.line_entry = nil
  data.reset_jump = nil
  data.cursor_bounds = nil
  data.prev_compressible = nil
  data.insert_move_autocmd = nil

  buffer.render()
end

function buffer.clear_extmarks(...)
  local extmarks = vim.api.nvim_buf_get_extmarks(
    data.handle,
    data.namespace,
    ...
  )

  for _, extmark in ipairs(extmarks) do
    vim.api.nvim_buf_del_extmark(data.handle, data.namespace, extmark[1])
  end
end

function buffer.clear_namespace(...)
  vim.api.nvim_buf_clear_namespace(data.handle, data.namespace, ...)
end

function buffer.add_highlight(...)
  vim.api.nvim_buf_add_highlight(data.handle, data.namespace, ...)
end

function buffer.set_lines(...)
  vim.api.nvim_buf_set_option(data.handle, 'modifiable', true)
  vim.api.nvim_buf_set_lines(data.handle, ...)
  vim.api.nvim_buf_set_option(data.handle, 'modifiable', false)
  vim.api.nvim_buf_set_option(data.handle, 'modified', false)
end

function buffer.process_event(_, path)
  vim.fn.timer_stop(data.sync_timer)

  data.resync_paths[path] = true

  data.sync_timer = vim.fn.timer_start(settings.sync_delay, function()
    buffer.synchronize()

    data.resync_paths = {}
  end)
end

function buffer.process_enter()
  vim.cmd('setlocal fillchars& fillchars=eob:\\  nowrap& nowrap')
end

function buffer.process_hidden()
  vim.cmd('setlocal fillchars& nowrap&')

  vim.w.carbon_lexplore_window = nil
  vim.w.carbon_fexplore_window = nil
end

function buffer.process_insert_move()
  local start_lnum = data.cursor_bounds.lnum - 1
  local start_col = data.cursor_bounds.col - 1
  local split_col = start_col
  local text = string.rep(' ', start_col)
    .. vim.fn.trim(vim.fn.getline(data.cursor_bounds.lnum), ' ', 1)

  for col = 1, #text do
    if string.sub(text, col, col) == '/' then
      split_col = col
    end
  end

  vim.api.nvim_buf_set_lines(0, start_lnum, start_lnum + 1, 1, { text })
  buffer.clear_extmarks({ start_lnum, 0 }, { start_lnum, -1 }, {})
  buffer.add_highlight('CarbonDir', start_lnum, 0, split_col)
  buffer.add_highlight('CarbonFile', start_lnum, split_col, -1)

  vim.fn.cursor(
    data.cursor_bounds.lnum,
    math.max(data.cursor_bounds.col, vim.fn.col('.'))
  )
end

function buffer.cancel_synchronization()
  vim.fn.timer_start(settings.sync_delay / 2, function()
    vim.fn.timer_stop(data.sync_timer)

    data.resync_paths = {}
  end)
end

return buffer
