local util = require('carbon.util')
local buffer = require('carbon.buffer')
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
  vim.cmd('command Carbon lua require("carbon").explore()')

  if settings.sync_on_cd then
    vim.cmd([[
      augroup CarbonDirChanged
        autocmd! DirChanged global lua require("carbon").cd()
      augroup END
    ]])
  end

  if type(settings.highlights) == 'table' then
    for group, properties in pairs(settings.highlights) do
      util.highlight(group, properties)
    end
  end

  if vim.fn.has('vim_starting') == 1 then
    if not settings.keep_netrw then
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

function carbon.edit()
  local entry = buffer.cursor().entry

  if entry.is_directory then
    entry.is_open = not entry.is_open

    buffer.render()
  else
    vim.cmd('edit ' .. entry.path)
  end
end

function carbon.split()
  local entry = buffer.cursor().entry

  if not entry.is_directory then
    vim.cmd('split ' .. entry.path)
  end
end

function carbon.vsplit()
  local entry = buffer.cursor().entry

  if not entry.is_directory then
    vim.cmd('vsplit ' .. entry.path)
  end
end

function carbon.explore()
  buffer.show()
end

function carbon.up()
  if buffer.up() then
    vim.fn.cursor(1, 1)
    buffer.render()
  end
end

function carbon.reset()
  if buffer.reset() then
    vim.fn.cursor(1, 1)
    buffer.render()
  end
end

function carbon.down()
  if buffer.down() then
    vim.fn.cursor(1, 1)
    buffer.render()
  end
end

function carbon.cd()
  if buffer.cd(vim.v.event.cwd) then
    vim.fn.cursor(1, 1)
    buffer.render()
  end
end

return carbon
