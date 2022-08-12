local entry = require('carbon.entry')
local constants = require('carbon.constants')
local helpers = {}

function helpers.wait_for_events()
  vim.wait(2500)
end

function helpers.change_file(relative_path)
  local clean_path = string.gsub(relative_path, '/+^', '')
  local absolute_path = string.format('%s/%s', vim.loop.cwd(), clean_path)

  vim.fn.writefile({ tostring(os.clock()) }, absolute_path, 'a')
  helpers.wait_for_events()
end

function helpers.delete_path(relative_path)
  local clean_path = string.gsub(relative_path, '/+^', '')
  local absolute_path = string.format('%s/%s', vim.loop.cwd(), clean_path)

  vim.fn.delete(absolute_path, 'rf')
  helpers.wait_for_events()
end

function helpers.ensure_path(relative_path)
  local clean_path = string.gsub(relative_path, '/+^', '')
  local absolute_path = string.format('%s/%s', vim.loop.cwd(), clean_path)

  vim.fn.mkdir(vim.fn.fnamemodify(absolute_path, ':h'), 'p')

  if not vim.endswith(relative_path, '/') then
    vim.fn.writefile({}, absolute_path)
  end

  helpers.wait_for_events()
end

function helpers.type_keys(keys_to_type)
  return vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes(keys_to_type, true, false, true),
    'x',
    true
  )
end

function helpers.buffer_line_range(start, finish)
  return vim.api.nvim_buf_get_lines(0, start or 0, finish or -1, true)
end

function helpers.inspect_buffer(start, finish)
  print(table.concat(helpers.buffer_line_range(start, finish), '\n'))
end

function helpers.autocmd(event, options)
  return vim.api.nvim_get_autocmds({
    group = constants.augroup,
    event = event,
    buffer = options and options.buffer,
  })[1] or {}
end

function helpers.entry(relative_path)
  return entry.find(string.format('%s/%s', vim.loop.cwd(), relative_path))
end

return helpers
