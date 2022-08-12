local util = require('carbon.util')
local buffer = require('carbon.buffer')
local watcher = require('carbon.watcher')
local settings = require('carbon.settings')
local carbon = {}
local data = { initialized = false }

function carbon.setup(user_settings)
  if data.initialized then
    return
  end

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
  if data.initialized then
    return
  else
    data.initialized = true
  end

  watcher.on('carbon:synchronize', buffer.defer_resync)

  util.command('Carbon', carbon.explore, { bang = true })
  util.command('Lcarbon', carbon.explore_left, { bang = true })
  util.command('Fcarbon', carbon.explore_float, { bang = true })

  for action in pairs(settings.defaults.actions) do
    vim.keymap.set('', util.plug(action), carbon[action])
  end

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

    pcall(vim.api.nvim_del_augroup_by_name, 'FileExplorer')
    pcall(vim.api.nvim_del_augroup_by_name, 'Network')

    util.command('Explore', carbon.explore, { bang = true })
    util.command('Lexplore', carbon.explore_left, { bang = true })
  end

  local argv = vim.fn.argv()
  local open = argv[1] and vim.fn.fnamemodify(argv[1], ':p') or vim.loop.cwd()

  if
    vim.fn.has('vim_starting')
    and settings.auto_open
    and util.is_directory(open)
  then
    local current_buffer = vim.api.nvim_win_get_buf(0)

    buffer.launch(open)

    if vim.api.nvim_buf_is_valid(current_buffer) then
      vim.api.nvim_buf_delete(current_buffer, { force = true })
    end
  end

  return carbon
end

function carbon.toggle_recursive()
  local line = buffer.cursor().line

  if line.entry.is_directory then
    line.entry:set_open(not line.entry:is_open(), true)

    buffer.render()
  end
end

function carbon.edit()
  local line = buffer.cursor().line

  if line.entry.is_directory then
    line.entry:set_open(not line.entry:is_open())

    buffer.render()
  elseif vim.w.carbon_lexplore_window then
    vim.cmd({ cmd = 'wincmd', args = { 'l' } })

    if vim.w.carbon_lexplore_window == vim.api.nvim_get_current_win() then
      vim.cmd({
        cmd = 'split',
        args = { line.entry.path },
        mods = { vertical = true, split = 'belowright' },
      })

      vim.api.nvim_win_set_width(
        util.bufwinid(buffer.handle()),
        settings.sidebar_width
      )
    else
      vim.cmd({ cmd = 'edit', args = { line.entry.path } })
    end
  else
    if vim.w.carbon_fexplore_window then
      vim.api.nvim_win_close(0, 1)
    end

    vim.cmd({ cmd = 'edit', args = { line.entry.path } })
  end
end

function carbon.split()
  local line = buffer.cursor().line

  if not line.entry.is_directory then
    if vim.w.carbon_fexplore_window then
      vim.api.nvim_win_close(0, 1)
    end

    vim.cmd({ cmd = 'split', args = { line.entry.path } })
  end
end

function carbon.vsplit()
  local line = buffer.cursor().line

  if not line.entry.is_directory then
    if vim.w.carbon_fexplore_window then
      vim.api.nvim_win_close(0, 1)
    end

    vim.cmd({ cmd = 'vsplit', args = { line.entry.path } })
  end
end

function carbon.explore(options)
  if options and options.bang or settings.always_reveal then
    buffer.expand_to_path(vim.fn.expand('%'))
  end

  buffer.show()
end

function carbon.explore_left(options)
  if options and options.bang or settings.always_reveal then
    buffer.expand_to_path(vim.fn.expand('%'))
  end

  local existing_win

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if pcall(vim.api.nvim_win_get_var, win, 'carbon_lexplore_window') then
      if vim.api.nvim_win_is_valid(win) then
        existing_win = win
      end

      break
    end
  end

  if existing_win then
    vim.api.nvim_set_current_win(existing_win)
    buffer.show()
  else
    vim.cmd({ cmd = 'split', mods = { vertical = true, split = 'leftabove' } })
    buffer.show()

    vim.api.nvim_win_set_width(
      util.bufwinid(buffer.handle()),
      settings.sidebar_width
    )

    vim.w.carbon_lexplore_window = vim.api.nvim_get_current_win()
  end
end

function carbon.explore_float(options)
  if options and options.bang or settings.always_reveal then
    buffer.expand_to_path(vim.fn.expand('%'))
  end

  local window_settings = settings.float_settings

  if type(window_settings) == 'function' then
    window_settings = window_settings()
  end

  window_settings = vim.deepcopy(window_settings)

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
    util.cursor(1, 1)
    buffer.render()
  end
end

function carbon.reset()
  if buffer.reset() then
    util.cursor(1, 1)
    buffer.render()
  end
end

function carbon.down()
  if buffer.down() then
    util.cursor(1, 1)
    buffer.render()
  end
end

function carbon.cd(path)
  local destination = path and path.file or path or vim.v.event.cwd

  if buffer.cd(destination) then
    util.cursor(1, 1)
    buffer.render()
  end
end

function carbon.quit()
  if #vim.api.nvim_list_wins() > 1 then
    vim.api.nvim_win_close(0, 1)
  elseif #vim.api.nvim_list_bufs() > 1 then
    vim.cmd({ cmd = 'bprevious' })
  end
end

function carbon.create()
  buffer.create()
end

function carbon.delete()
  buffer.delete()
end

function carbon.move()
  buffer.move()
end

return carbon
