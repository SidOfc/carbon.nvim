local util = require('carbon.util')
local watcher = {}
local data = {
  listeners = {},
  events = { change = {}, rename = {}, ['change-and-rename'] = {} },
}

function watcher.keep(callback)
  for path in pairs(data.listeners) do
    if not callback(path) then
      watcher.release(path)
    end
  end
end

function watcher.release(path)
  if data.listeners[path] then
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
      vim.schedule_wrap(function(error, filename, status)
        if status.change and status.rename then
          watcher.emit('change-and-rename', path, filename, error)
        elseif status.change then
          watcher.emit('change', path, filename, error)
        elseif status.rename then
          watcher.emit('rename', path, filename, error)
        end
      end)
    )
  end
end

function watcher.emit(event, ...)
  for callback in pairs(data.events[event]) do
    callback(event, ...)
  end
end

function watcher.on(event, callback)
  if event == '*' then
    for key in pairs(data.events) do
      data.events[key][callback] = callback
    end
  elseif type(event) == 'table' then
    for _, key in ipairs(event) do
      data.events[key][callback] = callback
    end
  else
    data.events[event] = {}
    data.events[event][callback] = callback
  end
end

function watcher.off(event, callback)
  if event == '*' then
    for key in pairs(data.events) do
      data.events[key][callback] = nil
    end
  elseif type(event) == 'table' then
    for _, key in ipairs(event) do
      data.events[key][callback] = nil
    end
  else
    data.events[event][callback] = nil
  end
end

return watcher
