local util = require('carbon.util')
local watcher = {}
local data = { listeners = {}, events = {} }

function watcher.keep(callback)
  for path in pairs(data.listeners) do
    if not callback(path) then
      watcher.release(path)
    end
  end
end

function watcher.release(path)
  if not path then
    for listener_path in pairs(data.listeners) do
      watcher.release(listener_path)
    end
  elseif data.listeners[path] then
    data.listeners[path]:stop()

    data.listeners[path] = nil
  end
end

function watcher.register(path)
  if not data.listeners[path] and not util.is_excluded(path) then
    data.listeners[path] = vim.loop.new_fs_event()

    data.listeners[path]:start(
      path,
      {},
      vim.schedule_wrap(function(error, filename)
        watcher.emit('carbon:synchronize', path, filename, error)
      end)
    )
  end
end

function watcher.emit(event, ...)
  for callback in pairs(data.events[event] or {}) do
    callback(event, ...)
  end

  for callback in pairs(data.events['*'] or {}) do
    callback(event, ...)
  end
end

function watcher.on(event, callback)
  if type(event) == 'table' then
    for _, key in ipairs(event) do
      watcher.on(key, callback)
    end
  elseif event then
    data.events[event] = data.events[event] or {}
    data.events[event][callback] = callback
  end
end

function watcher.off(event, callback)
  if not event then
    data.events = {}
  elseif type(event) == 'table' then
    for _, key in ipairs(event) do
      watcher.off(key, callback)
    end
  elseif data.events[event] and callback then
    data.events[event][callback] = nil
  elseif event then
    data.events[event] = {}
  else
    data.events[event] = nil
  end
end

function watcher.has(event, callback)
  return data.events[event] and data.events[event][callback] and true or false
end

function watcher.registered()
  return vim.tbl_keys(data.listeners)
end

return watcher
