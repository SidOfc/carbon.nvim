local util = require('carbon.util')
local view = require('carbon.view')
local entry = require('carbon.entry')
local constants = require('carbon.constants')
local helpers = {}

--- @param header string
function helpers.github_anchor(header)
  header = string.gsub(header, '^#+ ?', '')
  header = string.gsub(header, '<([%w-]+).->(.-)</%1>', '%2')
  header = string.gsub(header, '[^%w%s]', '')
  header = string.gsub(header, '%s', '-')

  return string.lower(header)
end

--- @param relative_path string
function helpers.repo_path(relative_path)
  return string.format('%s/%s', vim.env.CARBON_REPO_ROOT, relative_path)
end

--- @param relative_path string
function helpers.resolve(relative_path)
  local clean_path = string.gsub(relative_path, '/+^', '')

  return string.format('%s/%s', vim.uv.cwd(), clean_path)
end

--- @param relative_path string
function helpers.change_file(relative_path)
  vim.fn.writefile(
    { tostring(os.clock()) },
    helpers.resolve(relative_path),
    'a'
  )
end

--- @param relative_path string
function helpers.delete_path(relative_path)
  vim.fs.rm(helpers.resolve(relative_path), { recursive = true })
end

--- @param relative_path string
function helpers.has_path(relative_path)
  return vim.uv.fs_stat(helpers.resolve(relative_path)) ~= nil
end

--- @param relative_path string
function helpers.is_directory(relative_path)
  return (vim.uv.fs_stat(helpers.resolve(relative_path)) or {}).type
    == 'directory'
end

--- @param relative_path string
function helpers.ensure_path(relative_path)
  local absolute_path = helpers.resolve(relative_path)

  vim.fn.mkdir(vim.fs.dirname(absolute_path), 'p')

  if not vim.endswith(relative_path, '/') then
    vim.fn.writefile({}, absolute_path)
  end
end

function helpers.poll_spy_calls(spy, call_count, timeout, interval, fast_only)
  timeout = math.max(0, timeout or 3000)
  call_count = math.max(0, call_count or 1)
  interval = interval or math.max(10, timeout / 100)

  vim.wait(timeout, function()
    return #spy.calls >= call_count
  end, interval, fast_only)
end

--- @param keys_to_type string
function helpers.type_keys(keys_to_type)
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes(keys_to_type, true, false, true),
    'x',
    false
  )
end

--- @param start? integer
--- @param finish? integer
--- @return string[]
function helpers.buffer_line_range(start, finish)
  return vim.api.nvim_buf_get_lines(0, start or 0, finish or -1, true)
end

--- @param start? integer
--- @param finish? integer
function helpers.inspect_buffer(start, finish)
  print(table.concat(helpers.buffer_line_range(start, finish), '\n'))
end

--- @param event string
--- @param options table | nil
--- @return vim.api.keyset.get_autocmds.ret | table
function helpers.autocmd(event, options)
  return vim.api.nvim_get_autocmds({
    group = constants.augroup,
    event = event,
    buffer = options and options.buffer,
  })[1] or {}
end

--- @param relative_path string
--- @return carbon.entry.Entry?
function helpers.entry(relative_path)
  return entry.find(string.format('%s/%s', vim.uv.cwd(), relative_path))
end

--- @param path string
--- @return boolean?
function helpers.is_open(path)
  return view.execute(function(current_view)
    return current_view:get_path_attr(path, 'open')
  end)
end

--- @param pattern? string
--- @return carbon.view.Line?
function helpers.line_with_file(pattern)
  return view.execute(function(current_view)
    return util.tbl_find(current_view:lines(), function(line)
      if pattern then
        return not line.entry.is_directory
          and string.match(line.entry.path, pattern)
      end

      return not line.entry.is_directory
    end)
  end)
end

--- @param absolute_path string
function helpers.markdown_info(absolute_path)
  local result = { tags = {}, refs = {}, header_tags = {}, header_refs = {} }
  local handle = io.open(absolute_path)
  local content = handle and handle:read('*a')
  local lines = content and vim.split(content, '\n')

  for tag in string.gmatch(content, '`:h %S+`') do
    local key = string.sub(tag, 5, -2)

    result.refs[key] = (result.refs[key] or 0) + 1
  end

  for tag in string.gmatch(content, '%(#%S+%)') do
    local key = string.sub(tag, 3, -2)

    result.header_refs[key] = (result.header_refs[key] or 0) + 1
  end

  for _, line in ipairs(lines or {}) do
    if vim.startswith(line, '#') then
      local key = helpers.github_anchor(line)

      result.header_tags[key] = (result.header_tags[key] or 0) + 1
    end
  end

  return result
end

--- @param absolute_path string
function helpers.help_info(absolute_path)
  local result = { tags = {}, refs = {} }
  local handle = io.open(absolute_path)
  local content = handle and handle:read('*a')

  for tag in string.gmatch(content or '', '[*|]%S+[*|]') do
    local key = string.sub(tag, 2, -2)
    local type = vim.startswith(tag, '*') and 'tags' or 'refs'

    result[type][key] = (result[type][key] or 0) + 1
  end

  if handle then
    handle:close()
  end

  return result
end

return helpers
