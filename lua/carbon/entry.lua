local watcher = require('carbon.watcher')

--- @class carbon.entry.Entry
--- @field raw_path string
--- @field path string
--- @field name string
--- @field parent carbon.entry.Entry?
--- @field is_directory boolean
--- @field is_executable boolean
--- @field is_symlink boolean
local entry = {}

entry.items = {}
entry.__index = entry

--- @param a carbon.entry.Entry
--- @param b carbon.entry.Entry
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

--- @param path string
--- @param parent carbon.entry.Entry?
--- @return carbon.entry.Entry
function entry.new(path, parent)
  local raw_path = path == '' and '/' or path
  local clean = string.gsub(raw_path, '/+$', '')
  local lstat = select(2, pcall(vim.uv.fs_lstat, raw_path)) or {}
  local is_executable = false
  local is_directory = lstat.type == 'directory'
  local is_symlink = lstat.type == 'link' and 1

  if is_symlink then
    local ok, stat = pcall(vim.uv.fs_stat, raw_path)

    if ok and stat then
      is_directory = stat.type == 'directory'
      is_symlink = 1
      lstat = stat
    else
      is_directory = false
      is_symlink = 2
    end
  end

  if lstat and lstat.mode and is_symlink ~= 2 and not is_directory then
    is_executable = bit.band(lstat.mode, 73) ~= 0
  end

  return setmetatable({
    raw_path = raw_path,
    path = clean,
    name = vim.fs.basename(clean),
    parent = parent,
    is_directory = is_directory,
    is_executable = is_executable,
    is_symlink = is_symlink,
  }, entry)
end

--- @param path string
--- @return carbon.entry.Entry?
function entry.find(path)
  for _, children in pairs(entry.items) do
    for _, child in ipairs(children) do
      if child.path == path then
        return child
      end
    end
  end
end

--- @param paths string[]?
function entry:synchronize(paths)
  if not self.is_directory then
    return
  end

  paths = paths or {}

  if paths[self.path] then
    paths[self.path] = nil

    local all_paths = {}
    local current_paths = {}
    local previous_paths = {}
    local previous_children = entry.items[self.path] or {}

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
    end, entry.items[self.parent.path]))
  end
end

--- @return carbon.entry.Entry[]
function entry:children()
  if self.is_directory and not self:has_children() then
    self:set_children(self:get_children())
  end

  return entry.items[self.path] or {}
end

--- @return boolean
function entry:has_children()
  return entry.items[self.path] and true or false
end

--- @param children carbon.entry.Entry[]?
function entry:set_children(children)
  entry.items[self.path] = children
end

--- @return carbon.entry.Entry[]
function entry:get_children()
  local entries = {}
  local handle = vim.uv.fs_scandir(self.raw_path)

  if type(handle) == 'userdata' then
    local function iterator()
      return vim.uv.fs_scandir_next(handle)
    end

    for name in iterator do
      entries[#entries + 1] = entry.new(self.path .. '/' .. name, self)
    end

    table.sort(entries)
  end

  return entries
end

return entry
