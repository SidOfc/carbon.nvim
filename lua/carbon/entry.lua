local util = require('carbon.util')
local watcher = require('carbon.watcher')
local entry = {}
local data = { children = {} }

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
  local clean = string.gsub(path, '/+$', '')
  local lstat = select(2, pcall(vim.loop.fs_lstat, clean)) or {}
  local is_executable = lstat.mode == 33261
  local is_directory = lstat.type == 'directory'
  local is_symlink = lstat.type == 'link' and 1

  if is_symlink and not select(2, pcall(vim.loop.fs_stat, clean)) then
    is_symlink = 2
  end

  return setmetatable({
    path = clean,
    name = vim.fn.fnamemodify(clean, ':t'),
    parent = parent,
    is_directory = is_directory,
    is_executable = is_executable,
    is_symlink = is_symlink,
  }, entry)
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

function entry:synchronize(paths)
  if not self.is_directory then
    return
  end

  paths = paths or {}

  if paths[self.path] then
    local all_paths = {}
    local current_paths = {}
    local previous_paths = {}
    local previous_children = data.children[self.path] or {}

    self:set_children(nil)

    for _, previous in ipairs(previous_children) do
      all_paths[previous.path] = true
      previous_paths[previous.path] = previous
    end

    for _, current in ipairs(self:children()) do
      all_paths[current.path] = true
      current_paths[current.path] = current
    end

    for path in pairs(all_paths) do
      local current = current_paths[path]
      local previous = previous_paths[path]

      if previous and current then
        if current.is_directory then
          current:synchronize(paths)
        end
      elseif previous then
        previous:terminate()
      end
    end
  elseif self:has_children() then
    for _, child in ipairs(self:children()) do
      if child.is_directory then
        child:synchronize(paths)
      end
    end
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

function entry:children()
  if self.is_directory and not self:has_children() then
    self:set_children(self:get_children())
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
  local entries = {}
  local handle = vim.loop.fs_scandir(self.path)

  if type(handle) == 'userdata' then
    local function iterator()
      return vim.loop.fs_scandir_next(handle)
    end

    for name in iterator do
      local absolute_path = self.path .. '/' .. name
      local relative_path = vim.fn.fnamemodify(absolute_path, ':.')

      if not util.is_excluded(relative_path) then
        entries[#entries + 1] = entry.new(absolute_path, self)
      end
    end

    table.sort(entries)
  end

  return entries
end

return entry
