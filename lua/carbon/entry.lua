local util = require('carbon.util')
local watcher = require('carbon.watcher')
local settings = require('carbon.settings')
local entry = {}
local data = { children = {}, open = {}, compressible = {} }

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

function entry.new(path, parent)
  local lstat = vim.loop.fs_lstat(path)
  local is_executable = bit.band(lstat.mode, 33261) == 33261
  local is_directory = lstat.type == 'directory'
  local is_symlink = lstat.type == 'link' and 1

  if is_symlink then
    is_symlink = vim.loop.fs_stat(path) and is_symlink or 2
  elseif is_directory then
    watcher.register(path)
  end

  return setmetatable({
    path = path,
    name = vim.fn.fnamemodify(path, ':t'),
    parent = parent,
    is_directory = is_directory,
    is_executable = is_executable,
    is_symlink = is_symlink,
  }, entry)
end

function entry.clean(path)
  for parent_path, children in pairs(data.children) do
    if not vim.startswith(parent_path, path) then
      watcher.release(parent_path)

      for _, child in ipairs(children) do
        watcher.release(child.path)
      end

      data.children[parent_path] = nil
    end
  end

  watcher.register(path)
end

function entry.find(path)
  for _, children in pairs(data.children) do
    for _, child in ipairs(children) do
      if child.path == path then
        return child
      end
    end
  end
end

function entry:synchronize()
  if not self.is_directory then
    return
  end

  if util.is_directory(self.path) then
    local current_paths = {}
    local previous_children = data.children[self.path] or {}
    data.children[self.path] = nil

    for _, previous in ipairs(previous_children) do
      watcher.release(previous.path)
    end

    for _, child in ipairs(self:children()) do
      current_paths[#current_paths + 1] = child.path
      local previous = util.tbl_find(previous_children, function(previous)
        return previous.path == child.path
      end)

      if previous then
        child:set_open(previous:is_open())

        if previous:has_children() then
          child:synchronize()
        end
      end
    end

    for _, child in ipairs(previous_children) do
      if not vim.tbl_contains(current_paths, child.path) then
        child:terminate()
      end
    end
  else
    self:terminate()
  end
end

function entry:terminate()
  watcher.release(self.path)

  if self:has_children() then
    for _, child in ipairs(self:children()) do
      child:terminate()
    end

    self:set_children(nil)
  end

  if self.parent and self.parent:has_children() then
    self.parent:set_children(vim.tbl_filter(function(sibling)
      return sibling.path ~= self.path
    end, data.children[self.parent.path]))
  end
end

function entry:set_compressible(value)
  data.compressible[self.path] = value
end

function entry:is_compressible()
  return data.compressible[self.path] == nil and true
    or data.compressible[self.path]
end

function entry:set_open(value)
  data.open[self.path] = value
end

function entry:is_open()
  return data.open[self.path] and true or false
end

function entry:children()
  if self.is_directory and not self:has_children() then
    data.children[self.path] = self:get_children()
  end

  return data.children[self.path] or {}
end

function entry:has_children()
  return data.children[self.path] and true or false
end

function entry:set_children(children)
  data.children[self.path] = children
end

function entry:get_children()
  local entries = vim.tbl_map(function(name)
    return entry.new(self.path .. '/' .. name, self)
  end, vim.fn.readdir(self.path))

  if type(settings.exclude) == 'table' then
    entries = vim.tbl_filter(function(child)
      for _, pattern in ipairs(settings.exclude) do
        if string.find(vim.fn.fnamemodify(child.path, ':.'), pattern) then
          watcher.release(child.path)

          return false
        end
      end

      return true
    end, entries)
  end

  table.sort(entries)

  return entries
end

return entry
