local entry = require('carbon.entry')
local constants = require('carbon.constants')
local helpers = {}

function helpers.resolve(relative_path)
  local clean_path = string.gsub(relative_path, '/+^', '')

  return string.format('%s/%s', vim.loop.cwd(), clean_path)
end

function helpers.change_file(relative_path)
  vim.fn.writefile(
    { tostring(os.clock()) },
    helpers.resolve(relative_path),
    'a'
  )
end

function helpers.delete_path(relative_path)
  vim.fn.delete(helpers.resolve(relative_path), 'rf')
end

function helpers.has_path(relative_path)
  return vim.loop.fs_stat(helpers.resolve(relative_path)) ~= nil
end

function helpers.is_directory(relative_path)
  return vim.fn.isdirectory(helpers.resolve(relative_path)) == 1
end

function helpers.ensure_path(relative_path)
  local absolute_path = helpers.resolve(relative_path)

  vim.fn.mkdir(vim.fn.fnamemodify(absolute_path, ':h'), 'p')

  if not vim.endswith(relative_path, '/') then
    vim.fn.writefile({}, absolute_path)
  end
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
