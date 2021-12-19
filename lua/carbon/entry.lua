local settings = require('carbon.settings')
local entry = {}
local children = {}
local empty_table = {}

function entry:new(path, parent)
  local resolved = vim.fn.resolve(path)
  local instance = setmetatable({
    path = path,
    name = vim.fn.fnamemodify(path, ':t'),
    parent = parent,
    is_symlink = false,
    is_selected = parent and parent.is_selected,
    is_directory = vim.fn.isdirectory(path) == 1,
    is_executable = vim.fn.executable(path) == 1,
  }, self)

  if resolved ~= path then
    instance.is_symlink = vim.fn.getftime(resolved) == -1 and 2 or 1
  end

  self.__index = self

  return instance
end

function entry:children()
  if self.is_directory and not self:has_children() then
    children[self.path] = self:get_children()
  end

  return children[self.path] or empty_table
end

function entry:has_children()
  return children[self.path] and true or false
end

function entry:get_children()
  local entries = vim.tbl_map(function(name)
    return entry:new(self.path .. '/' .. name, self)
  end, vim.fn.readdir(self.path))

  if type(settings.exclude) == 'table' then
    entries = vim.tbl_filter(function(entry)
      for _, pattern in ipairs(settings.exclude) do
        if string.find(entry.path, pattern) then
          return false
        end
      end

      return true
    end, entries)
  end

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

function entry:update_children(key, value, recursive)
  if self:has_children() then
    for _, child in ipairs(self:children()) do
      child[key] = value

      if recursive then
        child:update_children(key, value, recursive)
      end
    end
  end
end

function entry:has_selection()
  if self:has_children() then
    for _, child in ipairs(self:children()) do
      if child.is_selected or child.is_partial or child:has_selection() then
        return true
      end
    end
  end
end

return entry
