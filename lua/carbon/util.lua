local constants = require('carbon.constants')
local settings = require('carbon.settings')
local util = {}

--- @class carbon.util.AutocommandEvent
--- @field buf integer \<abuf>
--- @field data any Data passed from |nvim_exec_autocmds()|
--- @field event vim.api.keyset.events Name of event |autocmd-events|
--- @field file string \<afile> (not expanded to full path)
--- @field id integer Autocommand id
--- @field match string \<amatch> (expanded to full path)

--- @alias carbon.util.VariadicReturn ...
--- @alias carbon.util.Direction 'top' | 'right' | 'bottom' | 'left'
--- @alias carbon.util.AutocommandCallback fun(event: carbon.util.AutocommandEvent)
--- @alias carbon.util.Mapping table<table<string, string, string, table?>>

--- @class carbon.util.ScratchBufferSettings
--- @field name? string
--- @field filetype? 'carbon.explorer'
--- @field modifiable? boolean
--- @field modified? boolean
--- @field bufhidden? 'wipe'
--- @field mappings? carbon.util.Mapping[]
--- @field autocmds? table<string, carbon.util.AutocommandCallback>
--- @field lines? table<string>

--- @param lnum integer 1-based line number
--- @param buffer integer? Target {bufnr}. Default 0 (current buffer)
--- @return string
function util.get_line(lnum, buffer)
  return vim.api.nvim_buf_get_lines(buffer or 0, lnum - 1, lnum, true)[1]
end

--- @param path string
--- @param current_view? carbon.view.View
--- @return string
function util.explore_path(path, current_view)
  path = string.gsub(path, '%s', '')

  if path == '' then
    path = vim.uv.cwd() or ''
  end

  if not vim.startswith(path, '/') then
    local base_path = current_view and current_view.root.path or vim.uv.cwd()

    path = string.format('%s/%s', base_path, path)
  end

  return select(1, string.gsub(vim.fs.normalize(path), '/+$', ''))
end

--- @param path string
--- @return string normalized_path
function util.resolve(path)
  return select(
    1,
    string.gsub(vim.fs.abspath(vim.fs.normalize(path)), '/+$', '')
  )
end

--- @param path string
--- @return boolean
function util.is_excluded(path)
  if settings.exclude then
    for _, pattern in ipairs(settings.exclude) do
      if string.find(path, pattern) then
        return true
      end
    end
  end

  return false
end

--- Set cursor position to {row} {col} in current window
--- @param row integer 1-based line number
--- @param col integer 1-based column number
function util.cursor(row, col)
  vim.api.nvim_win_set_cursor(0, { row, col - 1 })
end

--- Check if {path} is a directory
--- @param path string?
--- @return boolean
function util.is_directory(path)
  return type(path) == 'string'
    and (vim.uv.fs_stat(path) or {}).type == 'directory'
end

--- @param filename string
--- @return string?
function util.extname(filename)
  if type(filename) == 'string' then
    local matches = vim.split(filename, '.', { plain = true })
    local last = matches[#matches]
    local first = matches[1]

    if last == '' or last == first then
      return nil
    end

    return last
  end
end

--- @param path string Path to make relative
--- @param base string? Parent path to remove from {path}. Default |vim.uv.cwd|
--- @return string relative_path
function util.relative_path(path, base)
  local base_path = base or vim.uv.cwd()
  base_path = base_path and vim.fs.abspath(vim.fs.normalize(base_path))

  if base_path and vim.startswith(path, base_path) then
    return string.sub(path, #base_path + 2)
  end

  return path
end

--- Generate normalized <plug> mapping name from {name}
--- @param name string
--- @return string normalized_plug_name
function util.plug(name)
  return string.format('<plug>(carbon-%s)', string.gsub(name, '_', '-'))
end

--- Returns table key in {tbl} for found {item}
--- @param tbl table
--- @param item unknown
--- @return unknown?
function util.tbl_key(tbl, item)
  for key, tbl_item in pairs(tbl) do
    if tbl_item == item then
      return key
    end
  end
end

--- Returns {value} and {key} when {callback} returns a truthy value
--- @generic K, V
--- @param tbl table<K, V>
--- @param callback fun(value: V, key: K): ...?
--- @return V?, K?
function util.tbl_find(tbl, callback)
  for key, value in pairs(tbl) do
    if callback(value, key) then
      return value, key
    end
  end
end

--- Exclude {keys} from {tbl}. Returns shallow copy.
--- @param tbl table
--- @param keys string[]
--- @return table
function util.tbl_except(tbl, keys)
  local result = {}

  for key, value in pairs(tbl) do
    if not vim.tbl_contains(keys, key) then
      result[key] = value
    end
  end

  return result
end

--- @param event vim.api.keyset.events | vim.api.keyset.events[] Event name(s) that will trigger the handler
--- @param cmd_or_callback string | fun(event: carbon.util.AutocommandEvent) `Command` or Lua `callback` to execute
--- @param opts vim.api.keyset.create_autocmd? Optional settings for vim.api.nvim_create_autocmd
function util.autocmd(event, cmd_or_callback, opts)
  return vim.api.nvim_create_autocmd(
    event,
    vim.tbl_extend('force', {
      group = constants.augroup,
      callback = cmd_or_callback,
    }, opts or {})
  )
end

--- @param event string Autocommand name
--- @param opts table? Additional options for vim.api.nvim_clear_autocmds
function util.clear_autocmd(event, opts)
  return vim.api.nvim_clear_autocmds(vim.tbl_extend('force', {
    group = constants.augroup,
    event = event,
  }, opts or {}))
end

--- Wraps |nvim_create_user_command|
--- @param lhs string Command name
--- @param rhs string | fun(args: vim.api.keyset.create_user_command.command_args) Command or Lua callback to execute
--- @param opts vim.api.keyset.user_command? Optional settings for vim.api.nvim_create_user_command
function util.command(lhs, rhs, opts)
  return vim.api.nvim_create_user_command(lhs, rhs, opts or {})
end

--- @param group string Highlight group name
--- @param opts table? Additional opts for vim.api.nvim_set_hl
function util.highlight(group, opts)
  local merged = vim.tbl_extend('force', { default = true }, opts or {})

  vim.api.nvim_set_hl(0, group, merged)
end

--- @param buf integer Buffer number
--- @return integer? win Window id from |nvim_list_wins|
function util.bufwinid(buf)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == buf then
      return win
    end
  end
end

--- @param name string Buffer name to find
--- @return integer? buf Buffer number from |nvim_list_bufs|
function util.find_buf_by_name(name)
  if name then
    name = vim.fs.normalize(name)

    return util.tbl_find(vim.api.nvim_list_bufs(), function(bufnr)
      return name == vim.fs.normalize(vim.api.nvim_buf_get_name(bufnr))
    end)
  end
end

--- @param options carbon.util.ScratchBufferSettings?
--- @return integer buf Buffer number
function util.create_scratch_buf(options)
  options = options or {}
  local found = util.find_buf_by_name(options.name)
  local buf = found or vim.api.nvim_create_buf(false, true)
  local buffer_options = vim.tbl_extend('force', {
    bufhidden = 'wipe',
    buftype = 'nofile',
    swapfile = false,
  }, util.tbl_except(options, { 'name', 'lines', 'mappings', 'autocmds' }))

  if options.name then
    local name = options.name --[[@as string]]

    vim.api.nvim_buf_set_name(buf, name == '' and '/' or name)
  end

  if options.lines then
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, options.lines)
    vim.api.nvim_set_option_value('modified', false, { buf = buf })
  end

  if options.mappings then
    util.set_buf_mappings(buf, options.mappings)
  end

  if options.autocmds then
    util.set_buf_autocmds(buf, options.autocmds)
  end

  for option, value in pairs(buffer_options) do
    vim.api.nvim_set_option_value(option, value, { buf = buf })
  end

  return buf
end

--- @param buf integer Buffer number
--- @param mappings carbon.util.Mapping[]
function util.set_buf_mappings(buf, mappings)
  for _, mapping in ipairs(mappings) do
    vim.keymap.set(
      mapping[1],
      mapping[2],
      mapping[3],
      vim.tbl_extend('force', mapping[4] or {}, { buffer = buf })
    )
  end
end

--- @param buf integer Buffer number
--- @param autocmds table<string, carbon.util.AutocommandCallback>
function util.set_buf_autocmds(buf, autocmds)
  for autocmd, rhs in pairs(autocmds) do
    util.autocmd(autocmd, rhs, { buffer = buf })
  end
end

--- @param win integer Window number
--- @param highlights table<string, string>
function util.set_winhl(win, highlights)
  local winhls = {}

  for source, target in pairs(highlights) do
    winhls[#winhls + 1] = source .. ':' .. target
  end

  local combined_winhls = table.concat(winhls, ',')

  vim.api.nvim_set_option_value('winhl', combined_winhls, { win = win })
end

--- @param buf integer Buffer number
--- @param ... unknown[] Additional arguments for vim.api.nvim_buf_get_extmarks
function util.clear_extmarks(buf, ...)
  local extmarks = vim.api.nvim_buf_get_extmarks(buf, constants.hl, ...)

  for _, extmark in ipairs(extmarks) do
    vim.api.nvim_buf_del_extmark(buf, constants.hl, extmark[1])
  end
end

--- @class carbon.util.Extmark
--- @field start_row integer
--- @field start_col integer
--- @field opts vim.api.keyset.set_extmark

--- @param buf integer Buffer number
--- @param extmark carbon.util.Extmark
function util.add_extmark(buf, extmark)
  vim.api.nvim_buf_set_extmark(
    buf,
    constants.hl,
    extmark.start_row,
    extmark.start_col,
    extmark.opts
  )
end

--- Wraps |vim.hl.range| with its {ns} parameter set to `carbon.constants.Constants.hl`.
--- All parameters  are forwarded to |vim.hl.range| as-is.
--- @param buf integer Buffer number
--- @param group integer | integer[] | string | string[] Highlight group
--- @param start [integer, integer] | string Start of region
--- @param finish [integer, integer] | string End of region
--- @param opts table? Optional settings
function util.add_highlight(buf, group, start, finish, opts)
  vim.hl.range(buf, constants.hl, group, start, finish, opts)
end

--- List windows neighboring {window_id} on selected {sides}
--- @param window_id integer
--- @param sides carbon.util.Direction[]
--- @return { origin: integer, position: carbon.util.Direction, target: integer }[]
function util.window_neighbors(window_id, sides)
  local original_window = vim.api.nvim_get_current_win()
  local result = {}

  for _, side in ipairs(sides or {}) do
    vim.api.nvim_set_current_win(window_id)
    vim.cmd.wincmd(constants.directions[side])

    local side_id = vim.api.nvim_get_current_win()
    local result_id = window_id ~= side_id and side_id or nil

    if result_id then
      result[#result + 1] = {
        origin = window_id,
        position = side,
        target = result_id,
      }
    end
  end

  vim.api.nvim_set_current_win(original_window)

  return result
end

--- @generic FnArgs
--- @param label string Profile debugging label
--- @param fn fun(...: FnArgs): ...
--- @param ... FnArgs
--- @return ... Callback return values
function util.profile(label, fn, ...)
  local start_ns = vim.uv.hrtime()
  local fn_result = { fn(...) }
  local elapsed_ms = (vim.uv.hrtime() - start_ns) / 1e6

  print('[' .. label .. ']' .. ' took: ' .. elapsed_ms .. 'ms')

  return unpack(fn_result)
end

--- @param mod table<string, unknown>
--- @param label string Label for |carbon-util-profile|
--- @param method_names string[] methods of {mod} to profile
function util.profile_module(mod, label, method_names)
  for _, method_name in ipairs(method_names or {}) do
    local original = mod[method_name]

    if type(original) == 'function' then
      mod[method_name] = function(...)
        return util.profile(label .. ':' .. method_name, original, ...)
      end
    end
  end
end

return util
