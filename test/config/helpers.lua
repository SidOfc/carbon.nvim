local util = require('carbon.util')
local view = require('carbon.view')
local entry = require('carbon.entry')
local constants = require('carbon.constants')
local helpers = {}

function helpers.github_anchor(header)
  header = string.gsub(header, '^#+ ?', '')
  header = string.gsub(header, '<([%w-]+).->(.-)</%1>', '%2')
  header = string.gsub(header, '[^%w%s]', '')
  header = string.gsub(header, '%s', '-')

  return string.lower(header)
end

function helpers.repo_path(relative_path)
  return string.format('%s/%s', vim.env.CARBON_REPO_ROOT, relative_path)
end

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

function helpers.is_open(path)
  return view.execute(function(ctx)
    return ctx.view:get_path_attr(path, 'open')
  end)
end

function helpers.line_with_file()
  return view.execute(function(ctx)
    return util.tbl_find(ctx.view:current_lines(), function(line)
      return not line.entry.is_directory
    end)
  end)
end

function helpers.markdown_info(absolute_path)
  local result = { tags = {}, refs = {}, header_tags = {}, header_refs = {} }
  local lines = vim.fn.readfile(absolute_path)
  local content = table.concat(lines, '\n')

  for tag in string.gmatch(content, '`:h %S+`') do
    local key = string.sub(tag, 5, -2)

    result.refs[key] = (result.refs[key] or 0) + 1
  end

  for tag in string.gmatch(content, '%(#%S+%)') do
    local key = string.sub(tag, 3, -2)

    result.header_refs[key] = (result.header_refs[key] or 0) + 1
  end

  for _, line in ipairs(lines) do
    if vim.startswith(line, '#') then
      local key = helpers.github_anchor(line)

      result.header_tags[key] = (result.header_tags[key] or 0) + 1
    end
  end

  return result
end

function helpers.help_info(absolute_path)
  local result = { tags = {}, refs = {} }
  local content = table.concat(vim.fn.readfile(absolute_path), '\n')

  for tag in string.gmatch(content, '[*|]%S+[*|]') do
    local key = string.sub(tag, 2, -2)
    local type = vim.startswith(tag, '*') and 'tags' or 'refs'

    result[type][key] = (result[type][key] or 0) + 1
  end

  return result
end

return helpers
