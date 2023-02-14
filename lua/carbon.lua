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

    if type(user_settings.highlights) == 'table' then
      settings.highlights =
        vim.tbl_extend('force', settings.highlights, user_settings.highlights)
    end
  end

  if vim.g.carbon_lazy_init ~= nil then
    vim.schedule(carbon.initialize)
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
  util.command('Rcarbon', carbon.explore_right, { bang = true })
  util.command('Fcarbon', carbon.explore_float, { bang = true })
  util.command('ToggleSidebarCarbon', carbon.toggle_sidebar, { bang = true })

  for action in pairs(settings.defaults.actions) do
    vim.keymap.set('', util.plug(action), carbon[action])
  end

  if settings.sync_on_cd then
    util.autocmd('DirChanged', carbon.cd, { pattern = 'global' })
  end

  util.autocmd('SessionLoadPost', carbon.session_load_post, { pattern = '*' })

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
    util.command('Rexplore', carbon.explore_right, { bang = true })
    util.command('ToggleSidebarExplore', carbon.toggle_sidebar, { bang = true })
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

function carbon.session_load_post(event)
  local buffer_name = vim.api.nvim_buf_get_name(event.buf)

  if string.match(buffer_name, 'carbon$') then
    vim.api.nvim_buf_set_name(event.buf, '_carbon')
    buffer.show()
    vim.api.nvim_buf_delete(event.buf, { force = true })

    if vim.api.nvim_win_get_width(0) == settings.sidebar_width then
      vim.w.carbon_sidebar_window = vim.api.nvim_get_current_win()
    end
  end
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
  local keepalt = #vim.fn.getreg('#') ~= 0

  if line.entry.is_directory then
    line.entry:set_open(not line.entry:is_open())

    buffer.render()
  elseif vim.w.carbon_sidebar_window then
    local split_right = vim.w.carbon_sidebar_split == 'botright'
    local split = split_right and 'topleft' or 'botright'
    local check_position = split_right and 'h' or 'l'

    vim.cmd({ cmd = 'wincmd', args = { check_position } })

    if vim.w.carbon_sidebar_window == vim.api.nvim_get_current_win() then
      vim.cmd({
        cmd = 'split',
        args = { line.entry.path },
        mods = { vertical = true, split = split },
      })

      vim.api.nvim_win_set_width(
        util.bufwinid(buffer.handle()),
        settings.sidebar_width
      )
    else
      vim.cmd({
        cmd = 'edit',
        args = { line.entry.path },
        mods = { keepalt = keepalt },
      })
    end
  else
    if vim.w.carbon_fexplore_window then
      vim.api.nvim_win_close(0, 1)
    end

    vim.cmd({
      cmd = 'edit',
      args = { line.entry.path },
      mods = { keepalt = keepalt },
    })
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

function carbon.toggle_sidebar(options)
  local current_win = vim.api.nvim_get_current_win()
  local existing_win = buffer.sidebar_window_id()

  if existing_win then
    vim.api.nvim_win_close(existing_win, 1)
  else
    local explore_options = vim.tbl_extend(
      'force',
      options or {},
      { position = settings.sidebar_position }
    )

    carbon.explore_sidebar(explore_options)

    if not settings.sidebar_toggle_focus then
      vim.api.nvim_set_current_win(current_win)
    end
  end
end

function carbon.explore_sidebar(options)
  if type(options) ~= 'table' then
    options = {}
  end

  if options.bang or settings.always_reveal then
    buffer.expand_to_path(vim.fn.expand('%'))
  end

  local existing_win = buffer.sidebar_window_id()
  local position = options.position or settings.sidebar_position
  local split = position == 'right' and 'botright' or 'topleft'

  if existing_win then
    vim.api.nvim_set_current_win(existing_win)
    buffer.show()
  else
    vim.cmd({ cmd = 'split', mods = { vertical = true, split = split } })
    buffer.show()
    vim.api.nvim_win_set_width(0, settings.sidebar_width)

    vim.w.carbon_sidebar_window = vim.api.nvim_get_current_win()
    vim.w.carbon_sidebar_split = split
  end
end

function carbon.explore_left(options)
  local existing_win = buffer.sidebar_window_id()

  if existing_win and buffer.sidebar_window_split() ~= 'topleft' then
    vim.api.nvim_win_close(existing_win, 1)
  end

  carbon.explore_sidebar(
    vim.tbl_extend('force', options or {}, { position = 'left' })
  )
end

function carbon.explore_right(options)
  local existing_win = buffer.sidebar_window_id()

  if existing_win and buffer.sidebar_window_split() ~= 'botright' then
    vim.api.nvim_win_close(existing_win, 1)
  end

  carbon.explore_sidebar(
    vim.tbl_extend('force', options or {}, { position = 'right' })
  )
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

function carbon.close_parent()
  local count = 0
  local lines = { unpack(buffer.lines(), 2) }
  local entry = buffer.cursor().line.entry
  local line

  while count < vim.v.count1 do
    line = util.tbl_find(lines, function(current)
      return current.entry == entry.parent
        or vim.tbl_contains(current.path, entry.parent)
    end)

    if line then
      count = count + 1
      entry = line.path[1] and line.path[1].parent or line.entry

      entry:set_open(false)
    else
      break
    end
  end

  line = util.tbl_find(lines, function(current)
    return current.entry == entry or vim.tbl_contains(current.path, entry)
  end)

  if line then
    vim.fn.cursor(line.lnum, (line.depth + 1) * 2 + 1)
  end

  buffer.render()
end

return carbon
