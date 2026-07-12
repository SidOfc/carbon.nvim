local util = require('carbon.util')
local watcher = require('carbon.watcher')
local settings = require('carbon.settings')
local view = require('carbon.view')
local carbon = {}

--- @class carbon.ExploreOptions
--- @field sidebar? carbon.settings.SidebarPosition
--- @field bang? boolean
--- @field fargs? string[]

---@param user_settings? carbon.settings.UserSettings
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
    local open = argv[1] and vim.fs.abspath(argv[1]) or vim.uv.cwd()
    local function create_command(lhs, rhs)
      return vim.api.nvim_create_user_command(lhs, rhs, {
        bang = true,
        nargs = '?',
        complete = 'dir',
      })
    end

    watcher.on('carbon:synchronize', function(_, path)
      view.resync(path)
    end)

    create_command('Carbon', carbon.explore)
    create_command('Rcarbon', carbon.explore_right)
    create_command('Lcarbon', carbon.explore_left)
    create_command('Fcarbon', carbon.explore_float)
    create_command('ToggleSidebarCarbon', carbon.toggle_sidebar)

    util.autocmd('SessionLoadPost', carbon.session_load_post, { pattern = '*' })
    util.autocmd('WinResized', carbon.win_resized, { pattern = '*' })

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

      create_command('Explore', carbon.explore)
      create_command('Lexplore', carbon.explore_left)
      create_command('Rexplore', carbon.explore_right)
      create_command('ToggleSidebarExplore', carbon.toggle_sidebar)
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
      view.activate({ path = open })
    end

    vim.g.carbon_initialized = true
  end
end

function carbon.win_resized()
  if vim.api.nvim_win_is_valid(view.sidebar.origin) then
    local window_width = vim.api.nvim_win_get_width(view.sidebar.origin)

    if window_width ~= settings.sidebar_width then
      --- @diagnostic disable-next-line: deprecated
      vim.api.nvim_win_set_width(view.sidebar.origin, settings.sidebar_width)
    end
  end
end

--- @param event carbon.util.AutocommandEvent
function carbon.session_load_post(event)
  if util.is_directory(event.file) then
    local window_id = util.bufwinid(event.buf)

    if not window_id then
      return
    end

    local window_width = vim.api.nvim_win_get_width(window_id)
    local is_sidebar = window_width == settings.sidebar_width

    view.activate({ path = event.file })
    view.execute(function(current_view)
      current_view:show()
    end)

    if is_sidebar then
      local neighbor = util.tbl_find(
        util.window_neighbors(window_id, { 'left', 'right' }),
        function(neighbor)
          return neighbor.target
        end
      )

      if neighbor then
        view.sidebar = neighbor
      end
    end
  end
end

function carbon.toggle_hidden()
  view.execute(function(current_view)
    current_view.show_hidden = not current_view.show_hidden

    current_view:update()
    current_view:render()
  end)
end

function carbon.toggle_recursive()
  view.execute(function(current_view)
    local cursor = current_view:cursor()

    if cursor.line.entry.is_directory then
      local function toggle_recursive(target, value)
        if target.is_directory then
          current_view:set_path_attr(target.path, 'open', value)

          if target:has_children() then
            for _, child in ipairs(target:children()) do
              toggle_recursive(child, value)
            end
          end
        end
      end

      toggle_recursive(
        cursor.line.entry,
        not current_view:get_path_attr(cursor.line.entry.path, 'open')
      )

      current_view:update()
      current_view:render()
    end
  end)
end

function carbon.tabe()
  view.execute(function(current_view)
    local cursor = current_view:cursor()

    view.handle_sidebar_or_float()
    vim.cmd.tabedit({
      vim.fn.fnameescape(cursor.line.entry.path),
      mods = { keepalt = #vim.fn.getreg('#') ~= 0 },
    })
  end)
end

function carbon.edit()
  view.execute(function(current_view)
    local cursor = current_view:cursor()

    if cursor.line.entry.is_directory then
      local open = current_view:get_path_attr(cursor.line.entry.path, 'open')

      current_view:set_path_attr(cursor.line.entry.path, 'open', not open)
      current_view:update()
      current_view:render()
    else
      view.handle_sidebar_or_float()
      vim.cmd.edit({
        vim.fn.fnameescape(cursor.line.entry.path),
        mods = { keepalt = #vim.fn.getreg('#') ~= 0 },
      })
    end
  end)
end

function carbon.split()
  view.execute(function(current_view)
    local cursor = current_view:cursor()

    if not cursor.line.entry.is_directory then
      if vim.w.carbon_fexplore_window then
        vim.api.nvim_win_close(0, true)
      end

      view.handle_sidebar_or_float()
      vim.cmd.split(vim.fn.fnameescape(cursor.line.entry.path))
    end
  end)
end

function carbon.vsplit()
  view.execute(function(current_view)
    local cursor = current_view:cursor()

    if not cursor.line.entry.is_directory then
      if vim.w.carbon_fexplore_window then
        vim.api.nvim_win_close(0, true)
      end

      view.handle_sidebar_or_float()
      vim.cmd.vsplit(vim.fn.fnameescape(cursor.line.entry.path))
    end
  end)
end

function carbon.up()
  view.execute(function(current_view)
    if current_view:up() then
      current_view:update()
      current_view:render()
      util.cursor(1, 1)
    end
  end)
end

function carbon.reset()
  view.execute(function(current_view)
    if current_view:reset() then
      current_view:update()
      current_view:render()
      util.cursor(1, 1)
    end
  end)
end

function carbon.down()
  view.execute(function(current_view)
    if current_view:down() then
      current_view:update()
      current_view:render()
      util.cursor(1, 1)
    end
  end)
end

--- @param path string | carbon.util.AutocommandEvent Path to cd into
function carbon.cd(path)
  view.execute(function(current_view)
    local destination = path and path.file or path or vim.v.event.cwd

    if current_view:cd(destination) then
      current_view:update()
      current_view:render()
      util.cursor(1, 1)
    end
  end)
end

--- @param opts? carbon.ExploreOptions
function carbon.explore(opts)
  local options = opts or {}
  local path =
    util.explore_path(options.fargs and options.fargs[1] or '', view.current())

  view.activate({ path = path, reveal = options.bang })
end

--- @param opts? carbon.ExploreOptions
function carbon.toggle_sidebar(opts)
  local current_win = vim.api.nvim_get_current_win()

  if vim.api.nvim_win_is_valid(view.sidebar.origin) then
    vim.api.nvim_win_close(view.sidebar.origin, true)
  else
    local explore_options = vim.tbl_extend(
      'force',
      opts or {},
      { sidebar = settings.sidebar_position }
    )

    carbon.explore_sidebar(explore_options)

    if not settings.sidebar_toggle_focus then
      vim.api.nvim_set_current_win(current_win)
    end
  end
end

--- @param opts? carbon.ExploreOptions
function carbon.explore_sidebar(opts)
  local options = opts or {}
  local sidebar = options.sidebar or settings.sidebar_position
  local path =
    util.explore_path(options.fargs and options.fargs[1] or '', view.current())

  view.activate({ path = path, reveal = options.bang, sidebar = sidebar })
end

--- @param opts? carbon.ExploreOptions
function carbon.explore_left(opts)
  if view.sidebar.position ~= 'left' then
    view.close_sidebar()
  end

  carbon.explore_sidebar(
    vim.tbl_extend('force', opts or {}, { sidebar = 'left' })
  )
end

--- @param opts? carbon.ExploreOptions
function carbon.explore_right(opts)
  if view.sidebar.position ~= 'right' then
    view.close_sidebar()
  end

  carbon.explore_sidebar(
    vim.tbl_extend('force', opts or {}, { sidebar = 'right' })
  )
end

--- @param opts? carbon.ExploreOptions
function carbon.explore_float(opts)
  local options = opts or {}
  local path =
    util.explore_path(options.fargs and options.fargs[1] or '', view.current())

  view.activate({ path = path, reveal = options.bang, float = true })
end

function carbon.explore_buf_dir(params)
  if vim.bo.filetype == 'carbon.explorer' then
    return
  end

  if params and params.file and util.is_directory(params.file) then
    view.activate({ path = params.file })
    view.execute(function(current_view)
      current_view:show()
    end)
  end
end

function carbon.quit()
  if #vim.api.nvim_list_wins() > 1 then
    vim.api.nvim_win_close(0, true)
  elseif #vim.api.nvim_list_bufs() > 1 then
    pcall(vim.cmd.bprevious)
  end
end

function carbon.create()
  view.execute(function(current_view)
    current_view:create()
  end)
end

function carbon.delete()
  view.execute(function(current_view)
    current_view:delete()
  end)
end

function carbon.move()
  view.execute(function(current_view)
    current_view:move()
  end)
end

function carbon.close_parent()
  view.execute(function(current_view)
    local count = 0
    local lines = { unpack(current_view:current_lines(), 2) }
    local cursor = current_view:cursor()
    local entry = cursor.line.entry
    local line

    while count < vim.v.count1 do
      line = util.tbl_find(lines, function(current)
        return current.entry == entry.parent
      end)

      if line then
        count = count + 1
        entry = line.entry

        current_view:set_path_attr(entry.path, 'open', false)
      else
        break
      end
    end

    line = util.tbl_find(lines, function(current)
      return current.entry == entry or vim.tbl_contains(current.path, entry)
    end)

    if line then
      vim.api.nvim_win_set_cursor(0, { line.lnum, (line.depth + 1) * 2 })
    end

    current_view:update()
    current_view:render()
  end)
end

return carbon
