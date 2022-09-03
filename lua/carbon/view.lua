local util = require('carbon.util')
local entry = require('carbon.entry')
local watcher = require('carbon.watcher')
local settings = require('carbon.settings')
local constants = require('carbon.constants')
local view = {}
local views = {}

view.__index = view
view.sidebar = { origin = -1, target = -1 }
view.float = { origin = -1, target = -1 }
view.resync_paths = {}

local function create_leave(ctx)
  vim.cmd.stopinsert()
  ctx.view:set_path_attr(ctx.target.path, 'compressible', ctx.prev_compressible)
  util.cursor(ctx.target_line.lnum, 1)
  vim.keymap.del('i', '<cr>', { buffer = 0 })
  vim.keymap.del('i', '<esc>', { buffer = 0 })
  util.clear_autocmd('CursorMovedI', { buffer = 0 })
  ctx.view:update()
  ctx.view:render()
end

local function create_confirm(ctx)
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

    create_leave(ctx)
    view.resync(vim.fn.fnamemodify(parent_directory, ':h'))
  end
end

local function create_cancel(ctx)
  return function()
    ctx.view:set_path_attr(ctx.target.path, 'open', ctx.prev_open)
    create_leave(ctx)
  end
end

local function create_insert_move(ctx)
  return function()
    local text = ctx.edit_prefix
      .. vim.trim(string.sub(vim.fn.getline('.'), ctx.edit_col))
    local last_slash_col = vim.fn.strridx(text, '/') + 1

    vim.api.nvim_buf_set_lines(0, ctx.edit_lnum, ctx.edit_lnum + 1, 1, { text })
    util.clear_extmarks(0, { ctx.edit_lnum, 0 }, { ctx.edit_lnum, -1 }, {})
    util.add_highlight(0, 'CarbonDir', ctx.edit_lnum, 0, last_slash_col)
    util.add_highlight(0, 'CarbonFile', ctx.edit_lnum, last_slash_col, -1)
    util.cursor(ctx.edit_lnum + 1, math.max(ctx.edit_col, vim.fn.col('.')))
  end
end

function view.get(path)
  local resolved = util.resolve(path)
  local found_view = util.tbl_find(views, function(target_view)
    return target_view.root.path == resolved
  end)

  if found_view then
    return found_view
  end

  local index = #views + 1
  local instance = setmetatable({
    index = index,
    initial = resolved,
    states = {},
    root = entry.new(resolved),
  }, view)

  views[index] = instance
  instance.index = index

  return instance
end

function view.activate(options_param)
  local options = options_param or {}
  local original_window = vim.api.nvim_get_current_win()
  local original_buffer = vim.api.nvim_get_current_buf()
  local original_buffer_valid = vim.api.nvim_buf_is_valid(original_buffer)
  local current_view = (options.path and view.get(options.path))
    or view.current()
    or view.get(vim.loop.cwd())

  if options.reveal or settings.always_reveal then
    current_view:expand_to_path(vim.fn.expand('%'))
  end

  if options.sidebar then
    if vim.api.nvim_win_is_valid(view.sidebar.origin) then
      vim.api.nvim_set_current_win(view.sidebar.origin)
    else
      vim.cmd.split({ mods = { vertical = true, split = 'leftabove' } })

      view.sidebar = {
        origin = vim.api.nvim_get_current_win(),
        target = original_window,
      }
    end

    vim.api.nvim_win_set_width(view.sidebar.origin, settings.sidebar_width)
    vim.api.nvim_win_set_buf(view.sidebar.origin, current_view:buffer())
  elseif options.float then
    local float_settings = settings.float_settings
      or settings.defaults.float_settings

    float_settings = type(float_settings) == 'function' and float_settings()
      or vim.deepcopy(float_settings)

    view.float = {
      origin = vim.api.nvim_open_win(current_view:buffer(), 1, float_settings),
      target = original_window,
    }

    vim.api.nvim_win_set_option(
      view.float.origin,
      'winhl',
      'FloatBorder:CarbonFloat,Normal:CarbonFloat'
    )
  else
    vim.api.nvim_win_set_buf(0, current_view:buffer())
  end

  if original_buffer_valid and options.delete_current_buf then
    vim.api.nvim_buf_delete(original_buffer, { force = true })
  end
end

function view.handle_sidebar_or_float()
  local current_window = vim.api.nvim_get_current_win()

  if current_window == view.sidebar.origin then
    if vim.api.nvim_win_is_valid(view.sidebar.target) then
      vim.api.nvim_set_current_win(view.sidebar.target)
    else
      vim.cmd.split({ mods = { vertical = true, split = 'belowright' } })

      view.sidebar.target = vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_width(view.sidebar.origin, settings.sidebar_width)
    end
  elseif current_window == view.float.origin then
    vim.api.nvim_win_close(0, true)
  end
end

function view.exists(index)
  return views[index] and true or false
end

function view.current()
  local bufnr = vim.api.nvim_get_current_buf()
  local ref = select(2, pcall(vim.api.nvim_buf_get_var, bufnr, 'carbon'))

  return ref and views[ref.index] or false
end

function view.execute(callback)
  local current_view = view.current()

  if current_view then
    return callback({ cursor = current_view:cursor(), view = current_view })
  end
end

function view.list()
  return views
end

function view.resync(path)
  view.resync_paths[path] = true

  if view.resync_timer and not view.resync_timer:is_closing() then
    view.resync_timer:close()
  end

  view.resync_timer = vim.defer_fn(function()
    for _, current_view in ipairs(views) do
      current_view.root:synchronize(view.resync_paths)
      current_view:update()
      current_view:render()
    end

    if not view.resync_timer:is_closing() then
      view.resync_timer:close()
    end

    view.resync_timer = nil
    view.resync_paths = {}
  end, settings.sync_delay)
end

function view:expand_to_path(path)
  local resolved = util.resolve(path)

  if vim.startswith(resolved, self.root.path) then
    local dirs = vim.split(string.sub(resolved, #self.root.path + 2), '/')
    local current = self.root

    for _, dir in ipairs(dirs) do
      current:children()

      current = entry.find(string.format('%s/%s', current.path, dir))

      if current then
        self:set_path_attr(current.path, 'open', true)
      else
        break
      end
    end

    if current and current.path == resolved then
      self.flash = current

      return true
    end

    return false
  end
end

function view:get_path_attr(path, attr)
  local state = self.states[path]
  local value = state and state[attr]

  if attr == 'compressible' and value == nil then
    return true
  end

  return value
end

function view:set_path_attr(path, attr, value)
  if not self.states[path] then
    self.states[path] = {}
  end

  self.states[path][attr] = value

  return value
end

function view:buffers()
  return vim.tbl_filter(function(bufnr)
    local ref = select(2, pcall(vim.api.nvim_buf_get_var, bufnr, 'carbon'))

    return ref and ref.index == self.index
  end, vim.api.nvim_list_bufs())
end

function view:update()
  self.cached_lines = nil
end

function view:render()
  local cursor
  local lines = {}
  local hls = {}

  for lnum, line_data in ipairs(self:current_lines()) do
    lines[#lines + 1] = line_data.line

    if self.flash and self.flash.path == line_data.entry.path then
      cursor = { lnum = lnum, col = 1 + (line_data.depth + 1) * 2 }
    end

    for _, hl in ipairs(line_data.highlights) do
      hls[#hls + 1] = { hl[1], lnum - 1, hl[2], hl[3] }
    end
  end

  for _, buf in ipairs(self:buffers()) do
    local current_mode = string.lower(vim.api.nvim_get_mode().mode)

    vim.api.nvim_buf_clear_namespace(buf, constants.hl, 0, -1)
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, 1, lines)
    vim.api.nvim_buf_set_option(buf, 'modified', false)

    if not string.find(current_mode, 'i') then
      vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    end

    for _, hl in ipairs(hls) do
      vim.api.nvim_buf_add_highlight(
        buf,
        constants.hl,
        hl[1],
        hl[2],
        hl[3],
        hl[4]
      )
    end
  end

  if cursor then
    util.cursor(cursor.lnum, cursor.col)

    if settings.flash then
      vim.defer_fn(function()
        self:focus_flash(
          settings.flash.duration,
          'CarbonFlash',
          { cursor.lnum - 1, cursor.col - 1 },
          { cursor.lnum - 1, -1 }
        )
      end, settings.flash.delay)
    end
  end

  self.flash = nil
end

function view:focus_flash(duration, group, start, finish)
  for _, buf in ipairs(self:buffers()) do
    vim.highlight.range(buf, constants.hl_tmp, group, start, finish, {})
  end

  vim.defer_fn(function()
    for _, buf in ipairs(self:buffers()) do
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_clear_namespace(buf, constants.hl_tmp, 0, -1)
      end
    end
  end, duration)
end

function view:buffer()
  local buffers = self:buffers()

  if buffers[1] then
    return buffers[1]
  end

  local mappings = {
    { 'n', 'i', '<nop>' },
    { 'n', 'I', '<nop>' },
    { 'n', 'o', '<nop>' },
    { 'n', 'O', '<nop>' },
  }

  for action, mapping in pairs(settings.actions or {}) do
    mapping = type(mapping) == 'string' and { mapping } or mapping or {}

    for _, key in ipairs(mapping) do
      mappings[#mappings + 1] =
        { 'n', key, util.plug(action), { nowait = true } }
    end
  end

  local buffer = util.create_scratch_buf({
    name = vim.fn.fnamemodify(self.root.path, ':t'),
    filetype = 'carbon.explorer',
    modifiable = false,
    modified = false,
    bufhidden = 'hide',
    mappings = mappings,
    autocmds = {
      BufHidden = function()
        self:hide()
      end,
      BufWinEnter = function()
        self:show()
      end,
    },
  })

  vim.api.nvim_buf_set_var(buffer, 'carbon', { index = self.index })

  return buffer
end

function view:hide() -- luacheck:ignore unused argument self
  vim.opt_local.wrap = vim.opt_global.wrap:get()
  vim.opt_local.spell = vim.opt_global.spell:get()
  vim.opt_local.fillchars = vim.opt_global.fillchars:get()

  view.sidebar = { origin = -1, target = -1 }
  view.float = { origin = -1, target = -1 }
end

function view:show()
  vim.opt_local.wrap = false
  vim.opt_local.spell = false
  vim.opt_local.fillchars = { eob = ' ' }

  self:render()
end

function view:up(count)
  local rerender = false
  local remaining = count or vim.v.count1

  while remaining > 0 do
    remaining = remaining - 1
    local new_root = entry.new(vim.fn.fnamemodify(self.root.path, ':h'))

    if new_root.path ~= self.root.path then
      rerender = true

      new_root:set_children(vim.tbl_map(function(child)
        if child.path == self.root.path then
          self:set_path_attr(child.path, 'open', true)
        end

        return child
      end, new_root:get_children()))

      self:set_root(new_root)
    end
  end

  return rerender
end

function view:reset()
  return self:cd(self.initial)
end

function view:cd(path)
  if path == self.root.path then
    return false
  elseif vim.startswith(self.root.path, path) then
    local new_depth = select(2, string.gsub(path, '/', ''))
    local current_depth = select(2, string.gsub(self.root.path, '/', ''))

    if current_depth - new_depth > 0 then
      return self:up(current_depth - new_depth)
    end
  else
    return self:set_root(entry.find(path) or entry.new(path))
  end
end

function view:down(count)
  local cursor = self:cursor()
  local new_root = cursor.line.path[count or vim.v.count1] or cursor.line.entry

  if not new_root.is_directory then
    new_root = new_root.parent
  end

  if new_root.path ~= self.root.path then
    self:set_path_attr(self.root.path, 'open', true)

    return self:set_root(new_root)
  end
end

function view:set_root(target)
  if type(target) == 'string' then
    target = entry.new(target)
  end

  if target.path == self.root.path then
    return false
  end

  self.root = target

  vim.api.nvim_buf_set_name(
    self:buffer(),
    vim.fn.fnamemodify(self.root.path, ':t')
  )

  watcher.keep(function(path)
    return vim.startswith(path, self.root.path)
  end)

  if settings.sync_pwd then
    vim.api.nvim_set_current_dir(self.root.path)
  end

  return true
end

function view:current_lines()
  if not self.cached_lines then
    self.cached_lines = self:lines()
  end

  return self.cached_lines
end

function view:lines(input_target, lines, depth)
  lines = lines or {}
  depth = depth or 0
  local target = input_target or self.root
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
      entry = self.root,
      line = self.root.name .. '/',
      highlights = { { 'CarbonDir', 0, -1 } },
      path = {},
    }

    watcher.register(self.root.path)
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
        and self:get_path_attr(tmp.path, 'compressible')
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

      if not is_empty and self:get_path_attr(tmp.path, 'open') then
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

    if tmp.is_symlink == 1 then
      file_group = 'CarbonSymlink'
    elseif tmp.is_symlink == 2 then
      file_group = 'CarbonBrokenSymlink'
    elseif tmp.is_executable then
      file_group = 'CarbonExe'
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

    if tmp.is_directory and self:get_path_attr(tmp.path, 'open') then
      self:lines(tmp, lines, depth + 1)
    end
  end

  return lines
end

function view:cursor(opts)
  local options = opts or {}
  local lines = self:current_lines()
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

function view:create()
  local ctx = self:cursor({ target_directory_only = true })

  ctx.view = self
  ctx.compact = ctx.target.is_directory and #ctx.target:children() == 0
  ctx.prev_open = self:get_path_attr(ctx.target.path, 'open')
  ctx.prev_compressible = self:get_path_attr(ctx.target.path, 'compressible')

  self:set_path_attr(ctx.target.path, 'open', true)
  self:set_path_attr(ctx.target.path, 'compressible', false)

  if ctx.compact then
    ctx.edit_prefix = ctx.line.line
    ctx.edit_lnum = ctx.line.lnum - 1
    ctx.edit_col = #ctx.edit_prefix + 1
    ctx.init_end_lnum = ctx.edit_lnum + 1
  else
    ctx.edit_prefix = string.rep('  ', ctx.target_line.depth + 2)
    ctx.edit_lnum = ctx.target_line.lnum + #self:lines(ctx.target)
    ctx.edit_col = #ctx.edit_prefix + 1
    ctx.init_end_lnum = ctx.edit_lnum
  end

  self:update()
  self:render()
  util.autocmd('CursorMovedI', create_insert_move(ctx), { buffer = 0 })
  vim.keymap.set('i', '<cr>', create_confirm(ctx), { buffer = 0 })
  vim.keymap.set('i', '<esc>', create_cancel(ctx), { buffer = 0 })
  vim.cmd.startinsert({ bang = true })
  vim.api.nvim_buf_set_option(0, 'modifiable', true)
  vim.api.nvim_buf_set_lines(
    0,
    ctx.edit_lnum,
    ctx.init_end_lnum,
    1,
    { ctx.edit_prefix }
  )
  util.cursor(ctx.edit_lnum + 1, ctx.edit_col)
end

function view:delete()
  local cursor = self:cursor()
  local targets = vim.list_extend(
    { unpack(cursor.line.path) },
    { cursor.line.entry }
  )

  local lnum_idx = cursor.line.lnum - 1
  local count = vim.v.count == 0 and #targets or vim.v.count1
  local path_idx = math.min(count, #targets)
  local target = targets[path_idx]
  local highlight = { 'CarbonFile', 2 + cursor.line.depth * 2, lnum_idx }

  if targets[path_idx].path == self.root.path then
    return
  end

  if target.is_directory then
    highlight[1] = 'CarbonDir'
  end

  for idx = 1, path_idx - 1 do
    highlight[2] = highlight[2] + #cursor.line.path[idx].name + 1
  end

  util.clear_extmarks(0, { lnum_idx, highlight[2] }, { lnum_idx, -1 }, {})
  util.add_highlight(0, 'CarbonDanger', lnum_idx, highlight[2], -1)
  util.confirm({
    row = cursor.line.lnum,
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
            view.resync(vim.fn.fnamemodify(target.path, ':h'))
          end
        end,
      },
      {
        label = 'cancel',
        shortcut = 'q',
        callback = function()
          util.clear_extmarks(0, { lnum_idx, 0 }, { lnum_idx, -1 }, {})

          for _, lhl in ipairs(cursor.line.highlights) do
            util.add_highlight(0, lhl[1], lnum_idx, lhl[2], lhl[3])
          end

          self:render()
        end,
      },
    },
  })
end

function view:move()
  local ctx = self:cursor()
  local target_line = ctx.target_line
  local targets = vim.list_extend(
    { unpack(target_line.path) },
    { target_line.entry }
  )
  local target_names = vim.tbl_map(function(part)
    return part.name
  end, targets)

  if ctx.target.path == self.root.path then
    return
  end

  local path_start = target_line.depth * 2 + 2
  local lnum_idx = target_line.lnum - 1
  local target_idx = util.tbl_key(targets, ctx.target)
  local clamped_names = { unpack(target_names, 1, target_idx - 1) }
  local start_hl = path_start + #table.concat(clamped_names, '/')

  if target_idx > 1 then
    start_hl = start_hl + 1
  end

  util.clear_extmarks(0, { lnum_idx, start_hl }, { lnum_idx, -1 }, {})
  util.add_highlight(0, 'CarbonPending', lnum_idx, start_hl, -1)
  vim.cmd.redraw({ bang = true })
  vim.cmd.echohl('CarbonPending')

  local updated_path = string.gsub(
    vim.fn.input({
      prompt = 'destination: ',
      default = ctx.target.path,
      cancelreturn = ctx.target.path,
    }),
    '/+$',
    ''
  )

  vim.cmd.echohl('None')
  vim.api.nvim_echo({ { ' ' } }, false, {})

  if updated_path == ctx.target.path then
    self:render()
  elseif vim.loop.fs_stat(updated_path) then
    self:render()
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
    view.resync(vim.fn.fnamemodify(ctx.target.path, ':h'))
  end
end

return view
