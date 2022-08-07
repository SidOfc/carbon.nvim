local constants = require('carbon.constants')
local settings = require('carbon.settings')
local util = {}

function util.is_excluded(path)
  if settings.exclude then
    for _, pattern in ipairs(settings.exclude) do
      if string.find(path, pattern) then
        return true
      end
    end
  end

  return false
end

function util.cursor(row, col)
  return vim.api.nvim_win_set_cursor(0, { row, col - 1 })
end

function util.is_directory(path)
  return (vim.loop.fs_stat(path) or {}).type == 'directory'
end

function util.plug(name)
  return string.format('<plug>(carbon-%s)', string.gsub(name, '_', '-'))
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

function util.autocmd(event, cmd_or_callback, opts)
  return vim.api.nvim_create_autocmd(
    event,
    vim.tbl_extend('force', {
      group = constants.augroup,
      callback = cmd_or_callback,
    }, opts or {})
  )
end

function util.clear_autocmd(event, opts)
  return vim.api.nvim_clear_autocmds(vim.tbl_extend('force', {
    group = constants.augroup,
    event = event,
  }, opts or {}))
end

function util.command(lhs, rhs, options)
  return vim.api.nvim_create_user_command(lhs, rhs, options or {})
end

function util.highlight(group, opts)
  local merged = vim.tbl_extend('force', { default = true }, opts or {})

  vim.api.nvim_set_hl(0, group, merged)
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
      mappings[#mappings + 1] = { 'n', string.char(ascii), '<nop>' }
    end
  end

  for _, action in ipairs(options.actions) do
    actions[action.label] = action

    if action.shortcut then
      mappings[#mappings + 1] = { 'n', action.shortcut, finish(action.label) }
      lines[#lines + 1] = ' [' .. action.shortcut .. '] ' .. action.label
    else
      lines[#lines + 1] = '     ' .. action.label
    end
  end

  mappings[#mappings + 1] = { 'n', '<esc>', finish('cancel') }
  mappings[#mappings + 1] = {
    'n',
    '<cr>',
    function()
      finish(string.sub(vim.fn.getline('.'), 6), true)
    end,
  }

  local buf = util.create_scratch_buf({
    modifiable = false,
    lines = lines,
    mappings = mappings,
    autocmds = {
      BufLeave = finish('cancel'),
      CursorMoved = function()
        util.cursor(vim.fn.line('.'), 3)
      end,
    },
  })

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    anchor = 'NW',
    border = 'single',
    style = 'minimal',
    row = options.row or vim.fn.line('.'),
    col = options.col or vim.fn.col('.'),
    height = #lines,
    width = 1 + math.max(unpack(vim.tbl_map(function(line)
      return #line
    end, lines))),
  })

  util.cursor(1, 3)
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
  local buffer_options = vim.tbl_extend('force', {
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

  for option, value in pairs(buffer_options) do
    vim.api.nvim_buf_set_option(buf, option, value)
  end

  return buf
end

function util.set_buf_mappings(buf, mappings)
  for _, mapping in ipairs(mappings) do
    vim.keymap.set(
      mapping[1],
      mapping[2],
      mapping[3],
      vim.tbl_extend('force', mapping[4] or {}, { buffer = buf })
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
