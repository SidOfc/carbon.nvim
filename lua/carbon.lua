local util = require('carbon.util')
local watcher = require('carbon.watcher')
local settings = require('carbon.settings')
local view = require('carbon.view')
local carbon = {}

function carbon.setup(user_settings)
  if type(user_settings) ~= 'table' then
    user_settings = {}
  end

  if not vim.g.carbon_initialized then
    if type(user_settings) == 'function' then
      user_settings(settings)
    elseif type(user_settings) == 'table' then
      local next = vim.tbl_deep_extend('force', settings, user_settings)

      for setting, value in pairs(next) do
        settings[setting] = value
      end
    end

    if type(user_settings.highlights) == 'table' then
      settings.highlights =
        vim.tbl_extend('force', settings.highlights, user_settings.highlights)
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

    if settings.open_on_dir then
      util.autocmd('BufWinEnter', carbon.explore_buf_dir, { pattern = '*' })
    end

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
  view.execute(function(ctx)
    if ctx.cursor.line.entry.is_directory then
      local function toggle_recursive(target, value)
        if target.is_directory then
          ctx.view:set_path_attr(target.path, 'open', value)

          if target:has_children() then
            for _, child in ipairs(target:children()) do
              toggle_recursive(child, value)
            end
          end
        end
      end

      toggle_recursive(
        ctx.cursor.line.entry,
        not ctx.view:get_path_attr(ctx.cursor.line.entry.path, 'open')
      )

      ctx.view:update()
      ctx.view:render()
    end
  end)
end

function carbon.edit()
  view.execute(function(ctx)
    if ctx.cursor.line.entry.is_directory then
      local open = ctx.view:get_path_attr(ctx.cursor.line.entry.path, 'open')

      ctx.view:set_path_attr(ctx.cursor.line.entry.path, 'open', not open)
      ctx.view:update()
      ctx.view:render()
    else
      view.handle_sidebar_or_float()
      vim.cmd.edit(ctx.cursor.line.entry.path)
    end
  end)
end

function carbon.split()
  view.execute(function(ctx)
    if not ctx.cursor.line.entry.is_directory then
      if vim.w.carbon_fexplore_window then
        vim.api.nvim_win_close(0, 1)
      end

      vim.cmd.split(ctx.cursor.line.entry.path)
    end
  end)
end

function carbon.vsplit()
  view.execute(function(ctx)
    if not ctx.cursor.line.entry.is_directory then
      if vim.w.carbon_fexplore_window then
        vim.api.nvim_win_close(0, 1)
      end

      vim.cmd.vsplit(ctx.cursor.line.entry.path)
    end
  end)
end

function carbon.up()
  view.execute(function(ctx)
    if ctx.view:up() then
      ctx.view:update()
      ctx.view:render()
      util.cursor(1, 1)
    end
  end)
end

function carbon.reset()
  view.execute(function(ctx)
    if ctx.view:reset() then
      ctx.view:update()
      ctx.view:render()
      util.cursor(1, 1)
    end
  end)
end

function carbon.down()
  view.execute(function(ctx)
    if ctx.view:down() then
      ctx.view:update()
      ctx.view:render()
      util.cursor(1, 1)
    end
  end)
end

function carbon.cd(path)
  view.execute(function(ctx)
    local destination = path and path.file or path or vim.v.event.cwd

    if ctx.view:cd(destination) then
      ctx.view:update()
      ctx.view:render()
      util.cursor(1, 1)
    end
  end)
end

function carbon.explore(options_param)
  local options = options_param or {}
  local path = options.fargs and string.gsub(options.fargs[1] or '', '%s', '')

  if path == '' then
    path = vim.loop.cwd()
  end

  view.activate({ path = path, reveal = options.bang })
end

function carbon.explore_left(options_param)
  local options = options_param or {}
  local path = options.fargs and string.gsub(options.fargs[1] or '', '%s', '')

  if path == '' then
    path = vim.loop.cwd()
  end

  view.activate({ path = path, reveal = options.bang, sidebar = true })
end

function carbon.explore_float(options_param)
  local options = options_param or {}
  local path = options.fargs and string.gsub(options.fargs[1] or '', '%s', '')

  if path == '' then
    path = vim.loop.cwd()
  end

  view.activate({ path = path, reveal = options.bang, float = true })
end

function carbon.explore_buf_dir(params)
  if vim.bo.filetype == 'carbon.explorer' then
    return
  end

  if params and params.file and util.is_directory(params.file) then
    view.activate({ path = params.file, delete_current_buf = true })
    view.execute(function(ctx)
      ctx.view:show()
    end)
  end
end

function carbon.quit()
  if #vim.api.nvim_list_wins() > 1 then
    vim.api.nvim_win_close(0, 1)
  elseif #vim.api.nvim_list_bufs() > 1 then
    pcall(vim.cmd.bprevious)
  end
end

function carbon.create()
  view.execute(function(ctx)
    ctx.view:create()
  end)
end

function carbon.delete()
  view.execute(function(ctx)
    ctx.view:delete()
  end)
end

function carbon.move()
  view.execute(function(ctx)
    ctx.view:move()
  end)
end

function carbon.close_parent()
  view.execute(function(ctx)
    local count = 0
    local lines = { unpack(ctx.view:current_lines(), 2) }
    local entry = ctx.cursor.line.entry
    local line

    while count < vim.v.count1 do
      line = util.tbl_find(lines, function(current)
        return current.entry == entry.parent
          or vim.tbl_contains(current.path, entry.parent)
      end)

      if line then
        count = count + 1
        entry = line.path[1] and line.path[1].parent or line.entry

        ctx.view:set_path_attr(entry.path, 'open', false)
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

    ctx.view:update()
    ctx.view:render()
  end)
end

return carbon
