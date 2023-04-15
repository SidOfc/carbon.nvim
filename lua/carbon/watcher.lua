local util = require('carbon.util')
local watcher = {}

watcher.listeners = {}
watcher.events = {}

function watcher.keep(callback)
  for path in pairs(watcher.listeners) do
    if not callback(path) then
      watcher.release(path)
    end
  end
end

function watcher.release(path)
  if not path then
    for listener_path in pairs(watcher.listeners) do
      watcher.release(listener_path)
    end
  elseif watcher.listeners[path] then
    watcher.listeners[path]:stop()

    watcher.listeners[path] = nil
  end
end

function watcher.register(path)
  if not watcher.listeners[path] and not util.is_excluded(path) then
    watcher.listeners[path] = vim.loop.new_fs_event()

    watcher.listeners[path]:start(
      path,
      {},
      vim.schedule_wrap(function(error, filename)
        watcher.emit('carbon:synchronize', path, filename, error)
      end)
    )
  end
end

function watcher.emit(event, ...)
  for callback in pairs(watcher.events[event] or {}) do
    callback(event, ...)
  end

  for callback in pairs(watcher.events['*'] or {}) do
    callback(event, ...)
  end
end

function watcher.on(event, callback)
  if type(event) == 'table' then
    for _, key in ipairs(event) do
      watcher.on(key, callback)
    end
  elseif event then
    watcher.events[event] = watcher.events[event] or {}
    watcher.events[event][callback] = callback
  end
end

function watcher.off(event, callback)
  if not event then
    watcher.events = {}
  elseif type(event) == 'table' then
    for _, key in ipairs(event) do
      watcher.off(key, callback)
    end
  elseif watcher.events[event] and callback then
    watcher.events[event][callback] = nil
  elseif watcher.events[event] then
    watcher.events[event] = {}
  else
    watcher.events[event] = nil
  end
end

function watcher.has(event, callback)
  return watcher.events[event] and watcher.events[event][callback] and true
    or false
end

function watcher.registered()
  return vim.tbl_keys(watcher.listeners)
end

return watcher
