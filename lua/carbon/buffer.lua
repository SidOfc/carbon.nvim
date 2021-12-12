local buffer = {}
local util = require('carbon.util')
local settings = require('carbon.settings')

local current = nil
local root = util.entry(vim.fn.getcwd(), -1)
local namespace = vim.api.nvim_create_namespace('carbon')

function buffer.current()
  if current and vim.api.nvim_buf_is_loaded(current) then
    return current
  end

  current = vim.api.nvim_create_buf(false, true)

  buffer.set('name', vim.fn.fnamemodify(vim.fn.getcwd(), ':t'))
  buffer.set('swapfile', false)
  buffer.set('filetype', 'carbon')
  buffer.set('bufhidden', 'hide')
  buffer.set('buftype', 'nofile')
  buffer.set('modifiable', false)

  if settings.create_mappings then
    buffer.map('n', 'm', '<Plug>(carbon-move)')
    buffer.map('n', 'c', '<Plug>(carbon-create)')
    buffer.map('n', 'd', '<Plug>(carbon-destroy)')
    buffer.map('n', '<Cr>', '<Plug>(carbon-cursor)')
    buffer.map('n', '<C-x>', '<Plug>(carbon-hsplit)')
    buffer.map('n', '<C-v>', '<Plug>(carbon-vsplit)')
  end

  return current
end

function buffer.set(option, value)
  if option == 'name' then
    vim.api.nvim_buf_set_name(buffer.current(), value)
  else
    vim.api.nvim_buf_set_option(buffer.current(), option, value)
  end

  return buffer
end

function buffer.map(mode, lhs, rhs, options)
  options = vim.tbl_deep_extend('force', { silent = true }, options or {})

  vim.api.nvim_buf_set_keymap(buffer.current(), mode, lhs, rhs, options)

  return buffer
end

function buffer.show()
  vim.api.nvim_win_set_buf(0, buffer.current())
  buffer.draw()

  return buffer
end

function buffer.draw()
  local buffer_handle = buffer.current()
  local entries = root.entries()
  local lines = vim.tbl_map(function(entry)
    return string.rep('  ', entry.depth) .. entry.name
  end, entries)

  buffer.set('modifiable', true)
  vim.api.nvim_buf_set_lines(buffer_handle, 0, -1, 1, lines)
  buffer.set('modifiable', false)
  vim.api.nvim_buf_clear_namespace(buffer_handle, namespace, 0, -1)

  for lnum, entry in ipairs(entries) do
    local group = 'CarbonFile'

    if entry.is_directory then
      group = 'CarbonDir'
    end

    vim.api.nvim_buf_add_highlight(
      buffer_handle,
      namespace,
      group,
      lnum - 1,
      entry.depth * 2,
      -1
    )
  end

  return buffer
end

function buffer.cursor_entry()
  return root.entries()[vim.fn.line('.')]
end

return buffer
