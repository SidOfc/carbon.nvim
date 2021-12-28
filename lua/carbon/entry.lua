local util = require('carbon.util')
local watcher = require('carbon.watcher')
local settings = require('carbon.settings')
local entry = { data = { children = {} } }

entry.__index = entry
entry.__lt = function(a, b)
  if a.is_directory and b.is_directory then
    return string.lower(a.name) < string.lower(b.name)
  elseif a.is_directory then
    return true
  elseif b.is_directory then
    return false
  end

  return string.lower(a.name) < string.lower(b.name)
end

function entry:clean(path)
  for child_path in pairs(entry.data.children) do
    if not vim.startswith(child_path, path) then
      watcher.release(child_path)

      for _, child in ipairs(entry.data.children[child_path]) do
        watcher.release(child.path)
      end

      entry.data.children[child_path] = nil
    end
  end

  watcher.register(path)
end

function entry:new(path, parent)
  local resolved = vim.fn.resolve(path)
  local instance = setmetatable({
    path = path,
    name = vim.fn.fnamemodify(path, ':t'),
    parent = parent,
    is_symlink = false,
    is_directory = vim.fn.isdirectory(path) == 1,
    is_executable = vim.fn.executable(path) == 1,
  }, self)

  if resolved ~= path then
    instance.is_symlink = vim.fn.getftime(resolved) == -1 and 2 or 1
  end

  if instance.is_directory then
    watcher.register(path)
  end

  return instance
end

function entry:find_child(path)
  if self:has_children() then
    for _, child in ipairs(self:children()) do
      if child.path == path then
        return child
      end

      local child_result = child:find_child(path)

      if child_result then
        return child_result
      end
    end
  end
end

function entry:synchronize()
  if self.is_directory then
    local previous_children = entry.data.children[self.path] or {}
    entry.data.children[self.path] = nil

    for _, previous in ipairs(previous_children) do
      watcher.release(previous.path)
    end

    for _, child in ipairs(self:children()) do
      local previous = util.tbl_find(previous_children, function(previous)
        return previous.path == child.path
      end)

      if previous then
        child.is_open = previous.is_open

        if previous:has_children() then
          child:synchronize()
        end
      end
    end
  end
end

function entry:children()
  if self.is_directory and not self:has_children() then
    entry.data.children[self.path] = self:get_children()
  end

  return entry.data.children[self.path] or {}
end

function entry:has_children()
  return entry.data.children[self.path] and true or false
end

function entry:get_children()
  local entries = vim.tbl_map(function(name)
    return entry:new(self.path .. '/' .. name, self)
  end, vim.fn.readdir(self.path))

  if type(settings.exclude) == 'table' then
    entries = vim.tbl_filter(function(entry)
      for _, pattern in ipairs(settings.exclude) do
        if string.find(vim.fn.fnamemodify(entry.path, ':.'), pattern) then
          watcher.release(entry.path)

          return false
        end
      end

      return true
    end, entries)
  end

  table.sort(entries)

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

return entry
