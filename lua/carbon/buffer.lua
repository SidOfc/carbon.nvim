local util = require('carbon.util')
local entry = require('carbon.entry')
local watcher = require('carbon.watcher')
local settings = require('carbon.settings')
local constants = require('carbon.constants')
local buffer = {}
local internal = {}
local open_cwd = vim.loop.cwd()
local data = { root = entry.new(open_cwd), resync_paths = {}, handle = -1 }
local file_icons

if settings.file_icons then
  local ok, module = pcall(require, 'nvim-web-devicons')

  if ok then
    file_icons = module
  end
end

function buffer.launch(target)
  buffer.set_root(target)
  buffer.show()

  open_cwd = data.root.path

  return data.root
end

function buffer.is_loaded()
  return vim.api.nvim_buf_is_loaded(data.handle)
end

function buffer.is_hidden()
  return not util.bufwinid(data.handle)
end

function buffer.handle()
  if buffer.is_loaded() then
    return data.handle
  end

  local mappings =
    { { 'n', 'i', '<nop>' }, { 'n', 'o', '<nop>' }, { 'n', 'O', '<nop>' } }

  for action, mapping in pairs(settings.actions or {}) do
    mapping = type(mapping) == 'string' and { mapping } or mapping or {}

    for _, key in ipairs(mapping) do
      mappings[#mappings + 1] =
        { 'n', key, util.plug(action), { nowait = true } }
    end
  end

  data.handle = util.create_scratch_buf({
    name = 'carbon',
    filetype = 'carbon.explorer',
    modifiable = false,
    modified = false,
    bufhidden = 'hide',
    mappings = mappings,
    autocmds = {
      BufHidden = function()
        buffer.process_hidden()
      end,
      BufWinEnter = function()
        buffer.process_enter()
      end,
    },
  })

  return data.handle
end

function buffer.sidebar_window_id()
  local existing_win

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if pcall(vim.api.nvim_win_get_var, win, 'carbon_sidebar_window') then
      if vim.api.nvim_win_is_valid(win) then
        existing_win = win
      end

      break
    end
  end

  return existing_win
end

function buffer.sidebar_window_split()
  local existing_win = buffer.sidebar_window_id()

  if existing_win then
    return vim.api.nvim_win_get_var(existing_win, 'carbon_sidebar_split')
  end
end

function buffer.show()
  vim.api.nvim_win_set_buf(0, buffer.handle())
  buffer.render()
end

function buffer.render()
  if not buffer.is_loaded() or buffer.is_hidden() then
    return
  end

  local cursor = nil
  local lines = {}
  local hls = {}

  for lnum, line_data in ipairs(buffer.lines()) do
    lines[#lines + 1] = line_data.line

    if data.flash and data.flash.path == line_data.entry.path then
      cursor = { lnum = lnum, col = 1 + (line_data.depth + 1) * 2 }
    end

    for _, hl in ipairs(line_data.highlights) do
      hls[#hls + 1] = { hl[1], lnum - 1, hl[2], hl[3] }
    end
  end

  buffer.clear_namespace(0, -1)
  buffer.set_lines(0, -1, lines)

  for _, hl in ipairs(hls) do
    buffer.add_highlight(unpack(hl))
  end

  if cursor then
    util.cursor(cursor.lnum, cursor.col)

    if settings.flash then
      vim.defer_fn(function()
        buffer.focus_flash(
          settings.flash.duration,
          'CarbonFlash',
          { cursor.lnum - 1, cursor.col - 1 },
          { cursor.lnum - 1, -1 }
        )
      end, settings.flash.delay)
    end
  end

  data.flash = nil
end

function buffer.expand_to_path(input_path)
  local path = vim.fn.fnamemodify(input_path, ':p')

  if vim.startswith(path, data.root.path) then
    local dirs = vim.split(string.sub(path, #data.root.path + 2), '/')
    local current = data.root

    for _, dir in ipairs(dirs) do
      current:children()

      current = entry.find(string.format('%s/%s', current.path, dir))

      if current then
        current:set_open(true)
      else
        break
      end
    end

    if current and current.path == path then
      data.flash = current

      return true
    end

    return false
  end
end

function buffer.cursor(opts)
  local options = opts or {}
  local lines = buffer.lines()
  local line = lines[vim.fn.line('.')]
  local target = line.entry
  local target_line

  if options.target_directory_only and not target.is_directory then
    target = target.parent
  end

  target = line.path[vim.v.count] or target
  target_line = util.tbl_find(lines, function(current)
    if current.entry.path == target.path then
      return true
    end

    return util.tbl_find(current.path, function(parent)
      if parent.path == target.path then
        return true
      end
    end)
  end)

  return { line = line, target = target, target_line = target_line }
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

    watcher.register(data.root.path)
  end

  for _, child in ipairs(target:children()) do
    local tmp = child
    local hls = {}
    local path = {}
    local lnum = 1 + #lines
    local indent = string.rep('  ', depth)
    local is_empty = true
    local indicator = ''
    local path_suffix = ''

    if settings.compress then
      while
        tmp.is_directory
        and #tmp:children() == 1
        and tmp:is_compressible()
      do
        watcher.register(tmp.path)

        path[#path + 1] = tmp
        tmp = tmp:children()[1]
      end
    end

    if tmp.is_directory then
      watcher.register(tmp.path)

      is_empty = #tmp:children() == 0
      path_suffix = '/'

      if not is_empty and tmp:is_open() then
        indicator = collapse_indicator
      elseif not is_empty then
        indicator = expand_indicator
      end
    end

    if is_empty then
      indent = indent .. '  '
    end

    local icon = ''
    local icon_highlight

    if file_icons and settings.file_icons and not tmp.is_directory then
      local info = {
        file_icons.get_icon(
          tmp.name .. path_suffix,
          vim.fn.fnamemodify(tmp.name, ':e'),
          { default = true }
        ),
      }

      icon = info[1] or ' '
      icon_highlight = info[2]
    end

    local link_group
    local full_path = tmp.name .. path_suffix
    local indent_end = #indent
    local icon_width = #icon ~= 0 and #icon + 1 or 0
    local indicator_width = #indicator ~= 0 and #indicator + 1 or 0
    local path_start = indent_end + icon_width + indicator_width
    local dir_path = table.concat(
      vim.tbl_map(function(parent)
        return parent.name
      end, path),
      '/'
    )

    if path[1] then
      full_path = dir_path .. '/' .. full_path
    end

    if tmp.is_symlink == 1 then
      link_group = 'CarbonSymlink'
    elseif tmp.is_symlink == 2 then
      link_group = 'CarbonBrokenSymlink'
    elseif tmp.is_executable then
      link_group = 'CarbonExe'
    end

    if indicator_width ~= 0 and not is_empty then
      hls[#hls + 1] =
        { 'CarbonIndicator', indent_end, indent_end + indicator_width }
    end

    if icon and icon_highlight then
      hls[#hls + 1] =
        { icon_highlight, indent_end + indicator_width, path_start - 1 }
    end

    if tmp.is_directory then
      hls[#hls + 1] = { link_group or 'CarbonDir', path_start, -1 }
    elseif path[1] then
      local dir_end = path_start + #dir_path + 1

      hls[#hls + 1] = { link_group or 'CarbonDir', path_start, dir_end }
      hls[#hls + 1] = { link_group or 'CarbonFile', dir_end, -1 }
    else
      hls[#hls + 1] = { link_group or 'CarbonFile', path_start, -1 }
    end

    local line_prefix = indent

    if indicator_width ~= 0 then
      line_prefix = line_prefix .. indicator .. ' '
    end

    if icon_width ~= 0 then
      line_prefix = line_prefix .. icon .. ' '
    end

    lines[#lines + 1] = {
      lnum = lnum,
      depth = depth,
      entry = tmp,
      line = line_prefix .. full_path,
      icon_width = icon_width,
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
  data.root:synchronize(data.resync_paths)
  buffer.render()

  data.resync_paths = {}
end

function buffer.up(count)
  local rerender = false
  local remaining = count or vim.v.count1

  while remaining > 0 do
    remaining = remaining - 1
    local new_root = entry.new(vim.fn.fnamemodify(data.root.path, ':h'))

    if new_root.path ~= data.root.path then
      rerender = true

      new_root:set_children(vim.tbl_map(function(child)
        if child.path == data.root.path then
          child:set_open(true)
          child:set_children(data.root:children())
        end

        return child
      end, new_root:get_children()))

      buffer.set_root(new_root)
    end
  end

  return rerender
end

function buffer.down(count)
  local line = buffer.cursor().line
  local new_root = line.path[count or vim.v.count1] or line.entry

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

  watcher.keep(function(path)
    return vim.startswith(path, data.root.path)
  end)

  if settings.sync_pwd then
    vim.api.nvim_set_current_dir(data.root.path)
  end

  return data.root
end

function buffer.reset()
  local rerender = buffer.cd(open_cwd)

  if rerender and not settings.sync_pwd then
    vim.api.nvim_set_current_dir(open_cwd)
  end

  return rerender
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

function buffer.delete()
  local line = buffer.cursor().line
  local targets = vim.list_extend({ unpack(line.path) }, { line.entry })

  local lnum_idx = line.lnum - 1
  local count = vim.v.count == 0 and #targets or vim.v.count1
  local path_idx = math.min(count, #targets)
  local target = targets[path_idx]
  local highlight =
    { 'CarbonFile', line.depth * 2 + 2 + line.icon_width, lnum_idx }

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
  util.confirm({
    row = line.lnum,
    col = highlight[2],
    highlight = 'CarbonDanger',
    actions = {
      {
        label = 'delete',
        shortcut = 'D',
        callback = function()
          local result =
            vim.fn.delete(target.path, target.is_directory and 'rf' or '')

          if result == -1 then
            vim.api.nvim_echo({
              { 'Failed to delete: ', 'CarbonDanger' },
              { vim.fn.fnamemodify(target.path, ':.'), 'CarbonIndicator' },
            }, false, {})
          else
            buffer.defer_resync(nil, vim.fn.fnamemodify(target.path, ':h'))
          end
        end,
      },
      {
        label = 'cancel',
        shortcut = 'q',
        callback = function()
          buffer.clear_extmarks({ lnum_idx, 0 }, { lnum_idx, -1 }, {})

          for _, lhl in ipairs(line.highlights) do
            buffer.add_highlight(lhl[1], lnum_idx, lhl[2], lhl[3])
          end

          buffer.render()
        end,
      },
    },
  })
end

function buffer.move()
  local ctx = buffer.cursor()
  local target_line = ctx.target_line
  local targets = vim.list_extend(
    { unpack(target_line.path) },
    { target_line.entry }
  )
  local target_names = vim.tbl_map(function(part)
    return part.name
  end, targets)

  if ctx.target.path == data.root.path then
    return
  end

  local path_start = target_line.depth * 2 + 2 + target_line.icon_width
  local lnum_idx = target_line.lnum - 1
  local target_idx = util.tbl_key(targets, ctx.target)
  local clamped_names = { unpack(target_names, 1, target_idx - 1) }
  local start_hl = path_start + #table.concat(clamped_names, '/')

  if target_idx > 1 then
    start_hl = start_hl + 1
  end

  buffer.clear_extmarks({ lnum_idx, start_hl }, { lnum_idx, -1 }, {})
  buffer.add_highlight('CarbonPending', lnum_idx, start_hl, -1)

  vim.cmd({ cmd = 'redraw', bang = true })
  vim.cmd({ cmd = 'echohl', args = { 'CarbonPending' } })

  local updated_path = string.gsub(
    vim.fn.input({
      prompt = 'destination: ',
      default = ctx.target.path,
      cancelreturn = ctx.target.path,
    }),
    '/+$',
    ''
  )

  vim.cmd({ cmd = 'echohl', args = { 'None' } })
  vim.api.nvim_echo({ { ' ' } }, false, {})

  if updated_path == ctx.target.path then
    buffer.render()
  elseif vim.loop.fs_stat(updated_path) then
    buffer.render()
    vim.api.nvim_echo({
      { 'Failed to move: ', 'CarbonDanger' },
      { vim.fn.fnamemodify(ctx.target.path, ':.'), 'CarbonIndicator' },
      { ' => ' },
      { vim.fn.fnamemodify(updated_path, ':.'), 'CarbonIndicator' },
      { ' (destination exists)', 'CarbonPending' },
    }, false, {})
  else
    local directory = vim.fn.fnamemodify(updated_path, ':h')
    local tmp_path = ctx.target.path

    if vim.startswith(updated_path, tmp_path) then
      tmp_path = vim.fn.tempname()

      vim.fn.rename(ctx.target.path, tmp_path)
    end

    vim.fn.mkdir(directory, 'p')
    vim.fn.rename(tmp_path, updated_path)
    buffer.defer_resync(nil, vim.fn.fnamemodify(ctx.target.path, ':h'))
  end
end

function buffer.create()
  local ctx = buffer.cursor({ target_directory_only = true })

  ctx.compact = ctx.target.is_directory and #ctx.target:children() == 0
  ctx.prev_open = ctx.target:is_open()
  ctx.prev_compressible = ctx.target:is_compressible()

  ctx.target:set_open(true)
  ctx.target:set_compressible(false)

  if ctx.compact then
    ctx.edit_prefix = ctx.line.line
    ctx.edit_lnum = ctx.line.lnum - 1
    ctx.edit_col = #ctx.edit_prefix + 1
    ctx.init_end_lnum = ctx.edit_lnum + 1
  else
    ctx.edit_prefix = string.rep('  ', ctx.target_line.depth + 2)
    ctx.edit_lnum = ctx.target_line.lnum + #buffer.lines(ctx.target)
    ctx.edit_col = #ctx.edit_prefix
    ctx.init_end_lnum = ctx.edit_lnum
  end

  buffer.render()
  buffer.set_lines(ctx.edit_lnum, ctx.init_end_lnum, { ctx.edit_prefix })
  util.autocmd('CursorMovedI', internal.create_insert_move(ctx), { buffer = 0 })
  vim.keymap.set('i', '<cr>', internal.create_confirm(ctx), { buffer = 0 })
  vim.keymap.set('i', '<esc>', internal.create_cancel(ctx), { buffer = 0 })
  util.cursor(ctx.edit_lnum + 1, ctx.edit_col)
  vim.api.nvim_buf_set_option(data.handle, 'modifiable', true)
  vim.cmd({ cmd = 'startinsert', bang = true })
end

function buffer.clear_extmarks(...)
  local extmarks = vim.api.nvim_buf_get_extmarks(data.handle, constants.hl, ...)

  for _, extmark in ipairs(extmarks) do
    vim.api.nvim_buf_del_extmark(data.handle, constants.hl, extmark[1])
  end
end

function buffer.clear_namespace(...)
  vim.api.nvim_buf_clear_namespace(data.handle, constants.hl, ...)
end

function buffer.add_highlight(...)
  vim.api.nvim_buf_add_highlight(data.handle, constants.hl, ...)
end

function buffer.set_lines(start_lnum, end_lnum, lines)
  local current_mode = string.lower(vim.api.nvim_get_mode().mode)

  vim.api.nvim_buf_set_option(data.handle, 'modifiable', true)
  vim.api.nvim_buf_set_lines(data.handle, start_lnum, end_lnum, 1, lines)
  vim.api.nvim_buf_set_option(data.handle, 'modified', false)

  if not string.find(current_mode, 'i') then
    vim.api.nvim_buf_set_option(data.handle, 'modifiable', false)
  end
end

function buffer.defer_resync(_, path)
  if data.resync_timer then
    data.resync_timer:stop()
  end

  data.resync_paths[path] = true
  data.resync_timer = vim.defer_fn(buffer.synchronize, settings.sync_delay)
end

function buffer.process_enter()
  vim.opt_local.wrap = false
  vim.opt_local.spell = false
  vim.opt_local.fillchars = { eob = ' ' }
end

function buffer.process_hidden()
  vim.opt_local.wrap = vim.opt_global.wrap:get()
  vim.opt_local.spell = vim.opt_global.spell:get()
  vim.opt_local.fillchars = vim.opt_global.fillchars:get()
  vim.w.carbon_sidebar_split = nil
  vim.w.carbon_sidebar_window = nil
  vim.w.carbon_fexplore_window = nil
end

function internal.create_confirm(ctx)
  return function()
    local text = vim.trim(string.sub(vim.fn.getline('.'), ctx.edit_col))
    local name = vim.fn.fnamemodify(text, ':t')
    local parent_directory = ctx.target.path
      .. '/'
      .. vim.trim(vim.fn.fnamemodify(text, ':h'))

    vim.fn.mkdir(parent_directory, 'p')

    if name ~= '' then
      vim.fn.writefile({}, parent_directory .. '/' .. name)
    end

    internal.create_leave(ctx)
    buffer.defer_resync(nil, vim.fn.fnamemodify(parent_directory, ':h'))
  end
end

function internal.create_cancel(ctx)
  return function()
    ctx.target:set_open(ctx.prev_open)
    internal.create_leave(ctx)
    buffer.render()
  end
end

function internal.create_leave(ctx)
  vim.cmd({ cmd = 'stopinsert' })
  ctx.target:set_compressible(ctx.prev_compressible)
  util.cursor(ctx.target_line.lnum, 1)
  vim.keymap.del('i', '<cr>', { buffer = 0 })
  vim.keymap.del('i', '<esc>', { buffer = 0 })
  util.clear_autocmd('CursorMovedI', { buffer = 0 })
end

function internal.create_insert_move(ctx)
  return function()
    local text = ctx.edit_prefix
      .. vim.trim(string.sub(vim.fn.getline('.'), ctx.edit_col))
    local last_slash_col = vim.fn.strridx(text, '/') + 1

    buffer.set_lines(ctx.edit_lnum, ctx.edit_lnum + 1, { text })
    buffer.clear_extmarks({ ctx.edit_lnum, 0 }, { ctx.edit_lnum, -1 }, {})
    buffer.add_highlight('CarbonDir', ctx.edit_lnum, 0, last_slash_col)
    buffer.add_highlight('CarbonFile', ctx.edit_lnum, last_slash_col, -1)
    util.cursor(ctx.edit_lnum + 1, math.max(ctx.edit_col, vim.fn.col('.')))
  end
end

function buffer.focus_flash(duration, group, start, finish)
  vim.highlight.range(data.handle, constants.hl_tmp, group, start, finish, {})
  vim.defer_fn(function()
    if buffer.is_loaded() then
      vim.api.nvim_buf_clear_namespace(data.handle, constants.hl_tmp, 0, -1)
    end
  end, duration)
end

return buffer
