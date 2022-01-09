local util = {}

function util.plug(name)
  return '<plug>(carbon-' .. name .. ')'
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

  if settings.buffer then
    vim.api.nvim_buf_set_keymap(settings.buffer, mode, lhs, rhs, options)
  else
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
  end
end

function util.command(lhs, rhs, options)
  vim.api.nvim_add_user_command(lhs, rhs, options or {})
end

function util.highlight(group, properties)
  if type(properties) == 'table' then
    local command = 'highlight ' .. group

    for property, value in pairs(properties) do
      command = command .. ' ' .. property .. '=' .. value
    end

    vim.cmd(command)
  end
end

return util
