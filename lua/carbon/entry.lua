local util = require('carbon.util')
local watcher = require('carbon.watcher')
local settings = require('carbon.settings')
local entry = { data = { children = {} } }
entry.__index = entry

function entry:new(path, parent)
  local resolved = vim.fn.resolve(path)
  local instance = setmetatable({
    path = path,
    name = vim.fn.fnamemodify(path, ':t'),
    parent = parent,
    is_symlink = false,
    is_partial = false,
    is_selected = parent and parent.is_selected,
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

function entry:refresh()
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
        child.is_partial = previous.is_partial
        child.is_selected = previous.is_selected

        if previous:has_children() then
          child:refresh()
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

function entry:toggle_selected()
  local parent = self.parent

  self.is_partial = false
  self.is_selected = not self.is_selected

  self:update_children('is_partial', false, true)
  self:update_children('is_selected', self.is_selected, true)

  while parent do
    parent.is_partial = parent:has_selection()

    if not self.is_selected then
      parent.is_selected = false
    end

    parent = parent.parent
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
