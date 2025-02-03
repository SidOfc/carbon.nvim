local constants = require('carbon.constants')
local settings = require('carbon.settings')
local util = {}

function util.get_line(lnum, buffer)
  return vim.api.nvim_buf_get_lines(buffer or 0, lnum - 1, lnum, true)[1]
end

function util.explore_path(path, current_view)
  path = string.gsub(path, '%s', '')

  if path == '' then
    path = vim.loop.cwd()
  end

  if not vim.startswith(path, '/') then
    local base_path = current_view and current_view.root.path or vim.loop.cwd()

    path = string.format('%s/%s', base_path, path)
  end

  return string.gsub(vim.fn.simplify(path), '/+$', '')
end

function util.resolve(path)
  return string.gsub(
    vim.fn.fnamemodify(vim.fs.normalize(path), ':p'),
    '/+$',
    ''
  )
end

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

function util.cursor(row, col)
  return vim.api.nvim_win_set_cursor(0, { row, col - 1 })
end

function util.is_directory(path)
  return (vim.loop.fs_stat(path) or {}).type == 'directory'
end

function util.plug(name)
  return string.format('<plug>(carbon-%s)', string.gsub(name, '_', '-'))
end

function util.tbl_key(tbl, item)
  for key, tbl_item in pairs(tbl) do
    if tbl_item == item then
      return key
    end
  end
end

function util.tbl_some(tbl, callback)
  for key, value in pairs(tbl) do
    if callback(value, key) then
      return true
    end
  end

  return false
end

function util.tbl_find(tbl, callback)
  for key, value in pairs(tbl) do
    if callback(value, key) then
      return value, key
    end
  end
end

function util.tbl_except(tbl, keys)
  local result = {}

  for key, value in pairs(tbl) do
    if not vim.tbl_contains(keys, key) then
      result[key] = value
    end
  end

  return result
end

function util.autocmd(event, cmd_or_callback, opts)
  return vim.api.nvim_create_autocmd(
    event,
    vim.tbl_extend('force', {
      group = constants.augroup,
      callback = cmd_or_callback,
    }, opts or {})
  )
end

function util.clear_autocmd(event, opts)
  return vim.api.nvim_clear_autocmds(vim.tbl_extend('force', {
    group = constants.augroup,
    event = event,
  }, opts or {}))
end

function util.command(lhs, rhs, options)
  return vim.api.nvim_create_user_command(lhs, rhs, options or {})
end

function util.highlight(group, opts)
  local merged = vim.tbl_extend('force', { default = true }, opts or {})

  vim.api.nvim_set_hl(0, group, merged)
end

function util.bufwinid(buf)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == buf then
      return win
    end
  end
end

function util.find_buf_by_name(name)
  return util.tbl_find(vim.api.nvim_list_bufs(), function(bufnr)
    return name == vim.api.nvim_buf_get_name(bufnr)
  end)
end

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
    vim.api.nvim_buf_set_name(buf, options.name == '' and '/' or options.name)
  end

  if options.lines then
    vim.api.nvim_buf_set_lines(buf, 0, -1, 1, options.lines)
    vim.api.nvim_buf_set_option(buf, 'modified', false)
  end

  if options.mappings then
    util.set_buf_mappings(buf, options.mappings)
  end

  if options.autocmds then
    util.set_buf_autocmds(buf, options.autocmds)
  end

  for option, value in pairs(buffer_options) do
    vim.api.nvim_buf_set_option(buf, option, value)
  end

  return buf
end

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

function util.set_buf_autocmds(buf, autocmds)
  for autocmd, rhs in pairs(autocmds) do
    util.autocmd(autocmd, rhs, { buffer = buf })
  end
end

function util.set_winhl(win, highlights)
  local winhls = {}

  for source, target in pairs(highlights) do
    winhls[#winhls + 1] = source .. ':' .. target
  end

  vim.api.nvim_win_set_option(win, 'winhl', table.concat(winhls, ','))
end

function util.clear_extmarks(buf, ...)
  local extmarks = vim.api.nvim_buf_get_extmarks(buf, constants.hl, ...)

  for _, extmark in ipairs(extmarks) do
    vim.api.nvim_buf_del_extmark(buf, constants.hl, extmark[1])
  end
end

function util.add_highlight(buf, ...)
  vim.hl.range(buf, constants.hl, ...)
end

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

return util
