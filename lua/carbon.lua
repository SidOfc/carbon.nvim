local util = require('carbon.util')
local buffer = require('carbon.buffer')
local settings = require('carbon.settings')
local carbon = {}

function carbon.setup(user_settings)
  settings.extend(user_settings)

  return carbon
end

function carbon.initialize(user_settings)
  settings.extend(user_settings)

  if util.has('vim_starting') then
    if settings.disable_netrw then
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
    end

    if settings.auto_open and util.is_directory(util.expand('%')) then
      local current_buffer = vim.api.nvim_win_get_buf(0)

      buffer.show()
      vim.api.nvim_buf_delete(current_buffer, { force = true })
    end
  end

  for group, properties in pairs(settings.highlight_groups) do
    util.highlight(group, properties)
  end

  vim.cmd('command Carbon call carbon#buffer#show()')

  return carbon
end

return carbon
