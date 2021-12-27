local util = {}

function util.map(settings)
  local args = {
    settings.mode or 'n',
    settings[1],
    settings[2],
    {
      noremap = settings.noremap,
      unique = settings.unique,
      silent = settings.silent,
      nowait = settings.nowait,
      script = settings.script,
      expr = settings.expr,
    },
  }

  if settings.buffer then
    vim.api.nvim_buf_set_keymap(settings.buffer, unpack(args))
  else
    vim.api.nvim_set_keymap(unpack(args))
  end
end

function util.tbl_find(tbl, callback)
  for key, value in pairs(tbl) do
    if callback(value, key) then
      return value, key
    end
  end
end

function util.plug_name(action)
  return '<plug>(carbon_' .. action .. ')'
end

function util.plug_call(action)
  return ':<C-U>call carbon#action("' .. action .. '")<cr>'
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

function util.count_times(callback)
  local count = vim.v.count1

  while count > 0 do
    count = count - 1

    callback()
  end

  return count
end

return util
