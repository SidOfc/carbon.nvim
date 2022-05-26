local util = {}
local data = {
  augroup = vim.api.nvim_create_augroup('Carbon', { clear = false }),
}

function util.scandir(path)
  local fs = vim.loop.fs_scandir(path)

  return function()
    return vim.loop.fs_scandir_next(fs)
  end
end

function util.str_last_index_of(str, char)
  for index = #str, 1, -1 do
    if string.sub(str, index, index) == char then
      return index
    end
  end
end

function util.get_line(lnum)
  lnum = lnum or vim.api.nvim_win_get_cursor(0)[1]

  return vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, 1)[1]
end

function util.cursor(row, col)
  return vim.api.nvim_win_set_cursor(0, { row, col })
end

function util.is_directory(path)
  local stat = vim.loop.fs_stat(path)

  return stat and stat.type == 'directory'
end

function util.plug(name)
  return '<plug>(carbon-' .. name .. ')'
end

function util.tbl_merge(...)
  return vim.tbl_extend('force', {}, ...)
end

function util.tbl_concat(...)
  local result = {}

  for idx = 1, select('#', ...) do
    for key, value in pairs(select(idx, ...)) do
      if type(key) == 'number' then
        result[#result + 1] = value
      else
        result[key] = value
      end
    end
  end

  return result
end

function util.tbl_slice(tbl, start, finish)
  local result = {}

  for index = start, finish or #tbl do
    result[#result + 1] = tbl[index]
  end

  return result
end

function util.tbl_key(tbl, item)
  for key, tbl_item in pairs(tbl) do
    if tbl_item == item then
      return key
    end
  end
end

function util.tbl_find(tbl, callback)
  for key, value in pairs(tbl) do
    if callback(value, key) then
      return value, key
    end
  end
end

function util.tbl_except(tbl, keys)
  local result = {}

  for key, value in pairs(tbl) do
    if not vim.tbl_contains(keys, key) then
      result[key] = value
    end
  end

  return result
end

function util.map(lhs, rhs, settings_param)
  local settings = settings_param or {}
  local options = util.tbl_except(settings, { 'mode', 'buffer' })
  local mode = settings.mode or 'n'

  if type(rhs) == 'function' then
    options.callback = rhs
    rhs = ''
  end

  options = util.tbl_merge(
    { silent = true, nowait = true, noremap = true },
    options
  )

  if settings.buffer then
    vim.api.nvim_buf_set_keymap(settings.buffer, mode, lhs, rhs, options)
  else
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
  end
end

function util.unmap(mode, lhs, settings)
  if settings and settings.buffer then
    vim.api.nvim_buf_del_keymap(settings.buffer, mode, lhs)
  else
    vim.api.nvim_del_keymap(mode, lhs)
  end
end

function util.autocmd(event, cmd_or_callback, opts)
  return vim.api.nvim_create_autocmd(
    event,
    util.tbl_merge({
      group = data.augroup,
      callback = cmd_or_callback,
    }, opts or {})
  )
end

function util.clear_autocmd(event, opts)
  return vim.api.nvim_clear_autocmds(util.tbl_merge({
    event = event,
    group = data.augroup,
  }, opts or {}))
end

function util.command(lhs, rhs, options)
  return vim.api.nvim_create_user_command(lhs, rhs, options or {})
end

function util.highlight(group, opts)
  vim.api.nvim_set_hl(0, group, util.tbl_merge({ default = true }, opts or {}))
end

function util.confirm(options)
  local guicursor = vim.o.guicursor
  local finished = false
  local actions = {}
  local mappings = {}
  local lines = {}

  local function finish(label, immediate)
    local function handler()
      if finished then
        return nil
      end

      finished = true
      local callback = actions[label] and actions[label].callback

      if type(callback) == 'function' then
        callback()
      end

      vim.api.nvim_set_option('guicursor', guicursor)
      vim.cmd({ cmd = 'close' })
    end

    if not immediate then
      return handler
    end

    handler()
  end

  for ascii = 32, 127 do
    if
      ascii < 48
      and ascii > 57
      and not vim.tbl_contains({ 38, 40, 74, 75, 106, 107 }, ascii)
    then
      mappings[#mappings + 1] = { string.char(ascii), '<nop>' }
    end
  end

  for _, action in ipairs(options.actions) do
    actions[action.label] = action

    if action.shortcut then
      mappings[#mappings + 1] = { action.shortcut, finish(action.label) }
      lines[#lines + 1] = ' [' .. action.shortcut .. '] ' .. action.label
    else
      lines[#lines + 1] = '     ' .. action.label
    end
  end

  mappings[#mappings + 1] = { '<esc>', finish('cancel') }
  mappings[#mappings + 1] = {
    '<cr>',
    function()
      finish(string.sub(util.get_line(), 6), true)
    end,
  }

  local buf = util.create_scratch_buf({ modifiable = false, lines = lines })
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    anchor = 'NW',
    border = 'single',
    style = 'minimal',
    row = options.row or vim.fn.line('.'),
    col = options.col or vim.fn.col('.'),
    height = #lines,
    width = math.max(unpack(vim.tbl_map(function(line)
      return #line + 1
    end, lines))),
  })

  util.set_buf_mappings(buf, mappings)
  util.set_buf_autocmds(buf, {
    BufLeave = finish('cancel'),
    CursorMoved = function()
      util.cursor(vim.fn.line('.'), 2)
    end,
  })

  vim.api.nvim_set_option('guicursor', 'n-v-c:hor100')
  vim.api.nvim_win_set_option(win, 'cursorline', true)
  util.set_winhl(win, {
    Normal = 'CarbonIndicator',
    FloatBorder = options.highlight or 'Normal',
    CursorLine = options.highlight or 'Normal',
  })
end

function util.bufwinid(buf)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == buf then
      return win
    end
  end
end

function util.create_scratch_buf(options)
  options = options or {}
  local buf = vim.api.nvim_create_buf(false, true)
  local settings = util.tbl_merge({
    bufhidden = 'wipe',
    buftype = 'nofile',
    swapfile = false,
  }, util.tbl_except(options, { 'name', 'lines', 'mappings', 'autocmds' }))

  if options.name then
    vim.api.nvim_buf_set_name(buf, options.name)
  end

  if options.lines then
    vim.api.nvim_buf_set_lines(buf, 0, -1, 1, options.lines)
    vim.api.nvim_buf_set_option(buf, 'modified', false)
  end

  if options.mappings then
    util.set_buf_mappings(buf, options.mappings)
  end

  if options.autocmds then
    util.set_buf_autocmds(buf, options.autocmds)
  end

  for option, value in pairs(settings) do
    vim.api.nvim_buf_set_option(buf, option, value)
  end

  return buf
end

function util.set_buf_mappings(buf, mappings)
  for _, mapping in ipairs(mappings) do
    util.map(
      mapping[1],
      mapping[2],
      util.tbl_merge(mapping[3] or {}, { buffer = buf })
    )
  end
end

function util.set_buf_autocmds(buf, autocmds)
  for autocmd, rhs in pairs(autocmds) do
    util.autocmd(autocmd, rhs, { buffer = buf })
  end
end

function util.set_winhl(win, highlights)
  local winhls = {}

  for source, target in pairs(highlights) do
    winhls[#winhls + 1] = source .. ':' .. target
  end

  vim.api.nvim_win_set_option(win, 'winhl', table.concat(winhls, ','))
end

return util
