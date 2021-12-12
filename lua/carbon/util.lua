local util = {}

function util.ls(path, depth)
  local entries = vim.tbl_map(function(name)
    return util.entry(path .. '/' .. name, depth or 0)
  end, vim.fn.readdir(path))

  table.sort(entries, function(a, b)
    if a.is_directory and b.is_directory then
      return string.lower(a.name) < string.lower(b.name)
    elseif a.is_directory then
      return true
    elseif b.is_directory then
      return false
    end

    return string.lower(a.name) < string.lower(b.name)
  end)

  return entries
end

function util.has(feature)
  return vim.fn.has(feature) == 1
end

function util.entry(path, depth)
  local children = nil
  local entry = {
    name = vim.fn.fnamemodify(path, ':t'),
    path = path,
    depth = depth or 0,
    is_open = false,
    is_directory = util.is_directory(path),
  }

  function entry.sync()
    if entry.is_directory then
      children = util.ls(entry.path, entry.depth + 1)
    end
  end

  function entry.children()
    if not children then
      entry.sync()
    end

    return children
  end

  function entry.entries(entries)
    entries = entries or {}

    for _, child in ipairs(entry.children()) do
      entries[#entries + 1] = child

      if child.is_directory and child.is_open then
        child.entries(entries)
      end
    end

    return entries
  end

  return entry
end

function util.expand(path)
  return vim.fn.fnamemodify(vim.fn.expand(path), ':p')
end

function util.ternary(condition, a, b)
  if condition then
    return a
  else
    return b
  end
end

function util.highlight(group, properties)
  local command = 'highlight ' .. group

  for property, value in pairs(properties) do
    command = command .. ' ' .. property .. '=' .. value
  end

  vim.cmd(command)
end

function util.is_directory(path)
  return vim.fn.isdirectory(path) == 1
end

return util
