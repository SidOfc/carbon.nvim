local settings = require('carbon.settings')
local entry = {}

local entries = {}
local watchers = {}
local children = {}
local empty_table = {}
local watch_handler = nil

function entry:set_watch_handler(handler)
  watch_handler = handler
end

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

  self.__index = self
  entries[path] = instance

  if resolved ~= path then
    instance.is_symlink = vim.fn.getftime(resolved) == -1 and 2 or 1
  end

  return instance
end

function entry:destroy()
  if watchers[self.path] then
    watchers[self.path]:stop()
  end

  watchers[self.path] = nil
  entries[self.path] = nil
  children[self.path] = nil

  for path, path_children in pairs(children) do
    children[path] = vim.tbl_filter(function(entry)
      return entry.path ~= self.path
    end, children[path])
  end

  if self:has_children() then
    for _, child in ipairs(self:children()) do
      child:destroy()
    end
  end
end

function entry:watch(options)
  if self.is_directory and not watchers[self.path] then
    watchers[self.path] = vim.loop.new_fs_event()

    watchers[self.path]:start(
      self.path,
      options or {},
      vim.schedule_wrap(function(error, filename, status)
        local full_path = self.path
        local current_time = os.time()

        if filename ~= vim.fn.fnamemodify(self.path, ':t') then
          full_path = self.path .. '/' .. filename
        end

        local is_entry = entries[full_path]
        local path_modified = vim.fn.getftime(full_path)
        local path_exists = path_modified ~= -1

        if is_entry and not path_exists then
          path_modified = current_time
        end

        if path_modified ~= current_time then
          return
        end

        if status.rename and path_exists and not is_entry then
          local parent = entries[vim.fn.fnamemodify(full_path, ':h')]

          if parent and parent:has_children() then
            table.insert(children[parent.path], entry:new(full_path, parent))
            table.sort(children[parent.path], function(a, b)
              if a.is_directory and b.is_directory then
                return string.lower(a.name) < string.lower(b.name)
              elseif a.is_directory then
                return true
              elseif b.is_directory then
                return false
              end

              return string.lower(a.name) < string.lower(b.name)
            end)
          end

          if watch_handler then
            watch_handler(full_path, 'create')
          end
        elseif status.rename and not path_exists and is_entry then
          entries[full_path]:destroy()

          if watch_handler then
            watch_handler(full_path, 'destroy')
          end
        elseif status.change then
          if watch_handler then
            watch_handler(full_path, 'change')
          end
        end
      end)
    )
  end

  if self:has_children() then
    for _, child in ipairs(self:children()) do
      if child.is_directory then
        child:watch(options)
      end
    end
  end
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

  self:watch()

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
