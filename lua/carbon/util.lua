local util = {}
local data = {
  guicursors = {},
  augroup = vim.api.nvim_create_augroup('Carbon', { clear = false }),
}

-- stylua: ignore
data.allowed_keys = {
  38, 40, 48, 49, 50, 51, 52,  53,
  54, 55, 56, 57, 74, 75, 106, 107
}

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

function util.tbl_find(tbl, callback)
  for key, value in pairs(tbl) do
    if callback(value, key) then
      return value, key
    end
  end
end

function util.tbl_except(tbl, keys)
  local settings = {}

  for setting, value in pairs(tbl) do
    if not vim.tbl_contains(keys, setting) then
      settings[setting] = value
    end
  end

  return settings
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

function util.autocmd(event, cmd_or_callback, opts)
  return vim.api.nvim_create_autocmd(
    event,
    util.tbl_merge({
      group = data.augroup,
      callback = cmd_or_callback,
    }, opts or {})
  )
end

function util.command(lhs, rhs, options)
  return vim.api.nvim_create_user_command(lhs, rhs, options or {})
end

function util.highlight(group, properties)
  if type(properties) == 'table' then
    local command = 'highlight default ' .. group

    for property, value in pairs(properties) do
      command = command .. ' ' .. property .. '=' .. value
    end

    vim.cmd(command)
  end
end

function util.confirm(options)
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

      util.pop_guicursor()
      vim.cmd('close')
    end

    if not immediate then
      return handler
    end

    handler()
  end

  for ascii = 32, 127 do
    if not vim.tbl_contains(data.allowed_keys, ascii) then
      mappings[#mappings + 1] = { string.char(ascii), '<nop>' }
    end
  end

  for idx, action in ipairs(options.actions) do
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
      finish(string.sub(vim.fn.getline('.'), 6), true)
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
      vim.fn.cursor(vim.fn.line('.'), 3)
    end,
  })

  vim.api.nvim_win_set_option(win, 'cursorline', true)
  util.push_guicursor('n-v-c:hor100')
  util.set_winhl(win, {
    Normal = 'CarbonIndicator',
    FloatBorder = options.highlight or 'Normal',
    CursorLine = options.highlight or 'Normal',
  })
end

function util.pop_guicursor()
  if data.guicursors[#data.guicursors] then
    vim.cmd('set guicursor=' .. data.guicursors[#data.guicursors])
    data.guicursors[#data.guicursors] = nil
  end
end

function util.push_guicursor(guicursor)
  data.guicursors[#data.guicursors + 1] = vim.o.guicursor
  vim.cmd('set guicursor=' .. guicursor)
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
