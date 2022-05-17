local util = require('carbon.util')
local buffer = require('carbon.buffer')
local watcher = require('carbon.watcher')
local settings = require('carbon.settings')
local carbon = {}

function carbon.setup(user_settings)
  if type(user_settings) == 'function' then
    user_settings(settings)
  else
    local next = vim.tbl_deep_extend('force', settings, user_settings)

    for setting, value in pairs(next) do
      settings[setting] = value
    end
  end

  return settings
end

function carbon.initialize()
  watcher.on('*', buffer.process_event)

  util.command('Carbon', carbon.explore)
  util.command('Lcarbon', carbon.explore_left)
  util.command('Fcarbon', carbon.explore_float)

  util.map(util.plug('up'), carbon.up)
  util.map(util.plug('down'), carbon.down)
  util.map(util.plug('edit'), carbon.edit)
  util.map(util.plug('reset'), carbon.reset)
  util.map(util.plug('split'), carbon.split)
  util.map(util.plug('vsplit'), carbon.vsplit)
  util.map(util.plug('create'), carbon.create)
  util.map(util.plug('delete'), carbon.delete)
  util.map(util.plug('quit'), carbon.quit)

  if settings.sync_on_cd then
    util.autocmd('DirChanged', carbon.cd, { pattern = 'global' })
  end

  if type(settings.highlights) == 'table' then
    for group, properties in pairs(settings.highlights) do
      util.highlight(group, properties)
    end
  end

  if not settings.keep_netrw then
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    util.command('Explore', 'Carbon')
    util.command('Lexplore', 'Lcarbon')
  end

  if settings.auto_open and vim.fn.isdirectory(vim.fn.expand('%:p')) == 1 then
    local current_buffer = vim.api.nvim_win_get_buf(0)

    buffer.show()
    vim.api.nvim_buf_delete(current_buffer, { force = true })
  end

  return carbon
end

function carbon.edit()
  local entry = buffer.cursor().entry

  if entry.is_directory then
    entry:set_open(not entry:is_open())

    buffer.render()
  elseif vim.w.carbon_lexplore_window then
    vim.cmd('wincmd l')

    if vim.w.carbon_lexplore_window == vim.api.nvim_get_current_win() then
      vim.cmd('vertical belowright split ' .. entry.path)
      vim.cmd('wincmd p')
      vim.cmd('vertical resize ' .. tostring(settings.sidebar_width))
      vim.cmd('wincmd p')
    else
      vim.cmd('edit ' .. entry.path)
    end
  else
    if vim.w.carbon_fexplore_window then
      vim.api.nvim_win_close(0, 1)
    end

    vim.cmd('edit ' .. entry.path)
  end
end

function carbon.split()
  local entry = buffer.cursor().entry

  if not entry.is_directory then
    if vim.w.carbon_fexplore_window then
      vim.api.nvim_win_close(0, 1)
    end

    vim.cmd('split ' .. entry.path)
  end
end

function carbon.vsplit()
  local entry = buffer.cursor().entry

  if not entry.is_directory then
    if vim.w.carbon_fexplore_window then
      vim.api.nvim_win_close(0, 1)
    end

    vim.cmd('vsplit ' .. entry.path)
  end
end

function carbon.explore()
  buffer.show()
end

function carbon.explore_left()
  vim.cmd('vertical leftabove split')
  vim.cmd('vertical resize ' .. tostring(settings.sidebar_width))
  buffer.show()

  vim.w.carbon_lexplore_window = vim.api.nvim_get_current_win()
end

function carbon.explore_float()
  local window_settings = settings.float_settings

  if type(window_settings) == 'function' then
    window_settings = window_settings()
  end

  local carbon_fexplore_window = vim.api.nvim_get_current_win()
  local window = vim.api.nvim_open_win(buffer.handle(), 1, window_settings)

  buffer.render()

  vim.api.nvim_win_set_option(
    window,
    'winhl',
    'FloatBorder:Normal,Normal:Normal'
  )

  vim.w.carbon_fexplore_window = carbon_fexplore_window
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

function carbon.cd(path)
  local destination = path and path.file or path or vim.v.event.cwd

  if buffer.cd(destination) then
    vim.fn.cursor(1, 1)
    buffer.render()
  end
end

function carbon.quit()
  if #vim.api.nvim_list_wins() > 1 then
    vim.api.nvim_win_close(0, 1)
  elseif #vim.api.nvim_list_bufs() > 1 then
    vim.cmd('try | b# | catch | endtry')
  end
end

function carbon.create()
  buffer.create()
end

function carbon.delete()
  buffer.delete()
end

return carbon
