local util = {}
local data = { indexed_callbacks = {} }

local function index_callback(callback)
  local index = #data.indexed_callbacks + 1
  data.indexed_callbacks[index] = callback

  return index
end

function util.plug(name)
  return '<plug>(carbon-' .. name .. ')'
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

function util.indexed_callback(index, ...)
  if type(data.indexed_callbacks[index]) == 'function' then
    return data.indexed_callbacks[index](...)
  end
end

function util.map(lhs, rhs, settings_param)
  local settings = settings_param or {}
  local options = util.tbl_except(settings, { 'mode', 'buffer', 'rhs_prefix' })
  local mode = settings.mode or 'n'

  if type(rhs) == 'function' then
    rhs = ':<c-u>lua require("carbon.util").indexed_callback('
      .. index_callback(rhs)
      .. ')<cr>'
  end

  rhs = (settings.rhs_prefix or '') .. rhs

  if settings.buffer then
    vim.api.nvim_buf_set_keymap(settings.buffer, mode, lhs, rhs, options)
  else
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
  end
end

function util.autocmd(group, event, aupat, rhs)
  if type(rhs) == 'function' then
    rhs = 'lua require("carbon.util").indexed_callback('
      .. index_callback(rhs)
      .. ')'
  end

  local autocmd = vim.fn.join({ 'autocmd!', event, aupat, rhs }, ' ')

  vim.cmd(vim.fn.join({ 'augroup ' .. group, autocmd, 'augroup END' }, '\n'))
end

function util.command(lhs, rhs, options)
  if not vim.api.nvim_add_user_command then
    if type(rhs) == 'function' then
      rhs = ':lua require("carbon.util").indexed_callback('
        .. index_callback(rhs)
        .. ')'
    end

    vim.cmd('command! ' .. lhs .. ' ' .. rhs)
  else
    vim.api.nvim_add_user_command(lhs, rhs, options or {})
  end
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

function util.confirm_action(options)
  options = options or {}
  local keep = { 'j', 'k' }
  local bound = {}
  local width = 0
  local height = 1
  local actions = {}
  local highlight = options.highlight or 'Normal'
  local guicursor = vim.o.guicursor

  for _, action in ipairs(options.actions) do
    for _, char in ipairs(vim.fn.split(action.name, '\\zs')) do
      if
        not bound[char]
        and char ~= 'c'
        and action.name ~= 'cancel'
        and type(action.execute) == 'function'
      then
        bound[char] = true
        width = math.max(width, #action.name)
        height = height + 1
        actions[#actions + 1] = {
          key = char,
          name = action.name,
          execute = action.execute,
        }

        break
      end
    end
  end

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    anchor = 'NW',
    border = 'single',
    style = 'minimal',
    width = width + 6,
    height = height,
    row = options.row or vim.fn.line('.'),
    col = options.col or vim.fn.col('.'),
  })

  local function exit()
    if vim.fn.win_getid() == win then
      for _, action in ipairs(options.actions) do
        if action.name == 'cancel' then
          action.execute({ win = win, buf = buf })

          break
        end
      end

      vim.cmd('set guicursor=' .. guicursor)
      vim.cmd('close')
    end
  end

  width = math.max(width, 6)
  actions[#actions + 1] = { key = 'c', name = 'cancel', execute = exit }

  vim.api.nvim_buf_set_lines(
    buf,
    0,
    -1,
    1,
    vim.tbl_map(function(action)
      return ' [' .. action.key .. '] ' .. action.name
    end, actions)
  )

  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'readonly', true)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'modified', false)
  vim.api.nvim_win_set_option(win, 'cursorline', true)
  vim.api.nvim_win_set_option(
    win,
    'winhl',
    'Normal:CarbonIndicator,FloatBorder:'
      .. highlight
      .. ',CursorLine:'
      .. highlight
  )

  for ascii = 32, 127 do
    local key = vim.fn.nr2char(ascii)

    if not vim.tbl_contains(keep, key) then
      util.map(
        key,
        '<nop>',
        { buffer = buf, silent = true, nowait = true, noremap = true }
      )
    end
  end

  for _, action in ipairs(actions) do
    util.map(action.key, function()
      action.execute()
      exit()
    end, { buffer = buf, silent = true, nowait = true, noremap = true })
  end

  util.map(
    '<esc>',
    exit,
    { buffer = buf, silent = true, nowait = true, noremap = true }
  )

  util.map('<cr>', function()
    local action_key = string.sub(vim.fn.getline('.'), 3, 3)

    for _, action in ipairs(actions) do
      if action.key == action_key then
        action.execute()
        exit()

        break
      end
    end
  end, { buffer = buf, silent = true, nowait = true, noremap = true })

  util.autocmd('CarbonDelete', 'ExitPre', '<buffer>', exit)
  util.autocmd('CarbonDelete', 'WinClosed', '<buffer>', exit)
  util.autocmd('CarbonDelete', 'BufLeave', '<buffer>', exit)
  util.autocmd('CarbonDelete', 'CursorMoved', '<buffer>', function()
    vim.fn.cursor(vim.fn.line('.'), 3)
  end)

  vim.cmd('set guicursor=n-v-c:hor10')

  return { actions, width, height }
end

return util
