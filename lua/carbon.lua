local util = require('carbon.util')
local watcher = require('carbon.watcher')
local settings = require('carbon.settings')
local view = require('carbon.view')
local carbon = {}

function carbon.setup(user_settings)
  if not vim.g.carbon_initialized then
    if type(user_settings) == 'function' then
      user_settings(settings)
    elseif type(user_settings) == 'table' then
      local next = vim.tbl_deep_extend('force', settings, user_settings)

      for setting, value in pairs(next) do
        settings[setting] = value
      end
    end

    local argv = vim.fn.argv()
    local open = argv[1] and vim.fn.fnamemodify(argv[1], ':p') or vim.loop.cwd()
    local command_opts = { bang = true, nargs = '?', complete = 'dir' }

    watcher.on('carbon:synchronize', function(_, path)
      view.resync(path)
    end)

    util.command('Carbon', carbon.explore, command_opts)
    util.command('Lcarbon', carbon.explore_left, command_opts)
    util.command('Fcarbon', carbon.explore_float, command_opts)

    if settings.sync_on_cd then
      util.autocmd('DirChanged', carbon.cd, { pattern = 'global' })
    end

    if not settings.keep_netrw then
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1

      pcall(vim.api.nvim_del_augroup_by_name, 'FileExplorer')
      pcall(vim.api.nvim_del_augroup_by_name, 'Network')

      util.command('Explore', carbon.explore, command_opts)
      util.command('Lexplore', carbon.explore_left, command_opts)
    end

    for action in pairs(settings.defaults.actions) do
      vim.keymap.set('', util.plug(action), carbon[action])
    end

    if type(settings.highlights) == 'table' then
      for group, properties in pairs(settings.highlights) do
        util.highlight(group, properties)
      end
    end

    if
      vim.fn.has('vim_starting')
      and settings.auto_open
      and util.is_directory(open)
    then
      view.activate({ path = open, delete_current_buf = true })
    end

    vim.g.carbon_initialized = true
  end
end

function carbon.toggle_recursive()
  view.execute(function(context)
    if context.cursor.line.entry.is_directory then
      context.cursor.line.entry:toggle_open(true)
      context.view:update()
      context.view:render()
    end
  end)
end

function carbon.edit()
  view.execute(function(context)
    if context.cursor.line.entry.is_directory then
      context.cursor.line.entry:toggle_open()
      context.view:update()
      context.view:render()
    else
      view.handle_sidebar_or_float()
      vim.cmd.edit(context.cursor.line.entry.path)
    end
  end)
end

function carbon.split()
  view.execute(function(context)
    if not context.cursor.line.entry.is_directory then
      if vim.w.carbon_fexplore_window then
        vim.api.nvim_win_close(0, 1)
      end

      vim.cmd.split(context.cursor.line.entry.path)
    end
  end)
end

function carbon.vsplit()
  view.execute(function(context)
    if not context.cursor.line.entry.is_directory then
      if vim.w.carbon_fexplore_window then
        vim.api.nvim_win_close(0, 1)
      end

      vim.cmd.vsplit(context.cursor.line.entry.path)
    end
  end)
end

function carbon.up()
  view.execute(function(context)
    if context.view:up() then
      context.view:update()
      context.view:render()
      util.cursor(1, 1)
    end
  end)
end

function carbon.reset()
  view.execute(function(context)
    if context.view:reset() then
      context.view:update()
      context.view:render()
      util.cursor(1, 1)
    end
  end)
end

function carbon.down()
  view.execute(function(context)
    if context.view:down() then
      context.view:update()
      context.view:render()
      util.cursor(1, 1)
    end
  end)
end

function carbon.cd(path)
  view.execute(function(context)
    local destination = path and path.file or path or vim.v.event.cwd

    if context.view:cd(destination) then
      context.view:update()
      context.view:render()
      util.cursor(1, 1)
    end
  end)
end

function carbon.explore(options_param)
  local options = options_param or {}
  local path = options.fargs and string.gsub(options.fargs[1], '%s', '') or ''

  if path == '' then
    path = vim.loop.cwd()
  end

  view.activate({ path = path, reveal = options.bang })
end

function carbon.explore_left(options_param)
  local options = options_param or {}
  local path = options.fargs and string.gsub(options.fargs[1], '%s', '') or ''

  if path == '' then
    path = vim.loop.cwd()
  end

  view.activate({ path = path, reveal = options.bang, sidebar = true })
end

function carbon.explore_float(options_param)
  local options = options_param or {}
  local path = options.fargs and string.gsub(options.fargs[1], '%s', '') or ''

  if path == '' then
    path = vim.loop.cwd()
  end

  view.activate({ path = path, reveal = options.bang, float = true })
end

function carbon.quit()
  if #vim.api.nvim_list_wins() > 1 then
    vim.api.nvim_win_close(0, 1)
  elseif #vim.api.nvim_list_bufs() > 1 then
    vim.cmd.bprevious()
  end
end

function carbon.create()
  view.execute(function(context)
    context.view:create()
  end)
end

function carbon.delete()
  view.execute(function(context)
    context.view:delete()
  end)
end

function carbon.move()
  view.execute(function(context)
    context.view:move()
  end)
end

return carbon
