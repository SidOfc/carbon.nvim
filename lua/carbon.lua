local util = require('carbon.util')
local buffer = require('carbon.buffer')
local actions = require('carbon.actions')
local settings = require('carbon.settings')
local carbon = {}

function carbon.setup(user_settings)
  local next = vim.tbl_deep_extend('force', settings, user_settings)

  for setting, value in pairs(next) do
    settings[setting] = value
  end

  return carbon
end

function carbon.initialize()
  vim.cmd('command Carbon call carbon#action("explore")')

  for action in pairs(actions) do
    util.map({ util.plug_name(action), util.plug_call(action) })
  end

  if type(settings.highlights) == 'table' then
    for group, properties in pairs(settings.highlights) do
      util.highlight(group, properties)
    end
  end

  if vim.fn.has('vim_starting') == 1 then
    if settings.disable_netrw then
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
    end

    if settings.auto_open and vim.fn.isdirectory(vim.fn.expand('%:p')) == 1 then
      local current_buffer = vim.api.nvim_win_get_buf(0)

      buffer.show()
      vim.api.nvim_buf_delete(current_buffer, { force = true })
    end
  end

  return carbon
end

function carbon.action(name)
  if type(actions[name]) == 'function' then
    actions[name]()
  end
end

return carbon
