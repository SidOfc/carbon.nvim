local util = {}

function util.tbl_find(tbl, callback)
  for key, value in pairs(tbl) do
    if callback(value, key) then
      return value, key
    end
  end
end

function util.tbl_object(tbl, options)
  local settings = {}
  local except = options and options.except or {}

  for setting, value in pairs(tbl) do
    if not vim.tbl_contains(except, setting) and type(setting) == 'string' then
      settings[setting] = value
    end
  end

  return settings
end

function util.plug(name)
  return '<plug>(carbon-' .. name .. ')'
end

function util.map(args)
  local mode = args.mode or 'n'
  local options = util.tbl_object(args, { except = { 'mode', 'buffer' } })

  if args.buffer then
    vim.api.nvim_buf_set_keymap(args.buffer, mode, args[1], args[2], options)
  else
    vim.api.nvim_set_keymap(mode, args[1], args[2], options)
  end
end

function util.command(args)
  vim.api.nvim_add_user_command(args[1], args[2], util.tbl_object(args))
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
