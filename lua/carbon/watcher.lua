local watcher = {}
local data = { listeners = {}, events = {} }

function watcher.clear()
  for path in pairs(data.listeners) do
    watcher.release(path)
  end
end

function watcher.release(path)
  if data.listeners[path] then
    data.listeners[path]:stop()

    data.listeners[path] = nil
  end
end

function watcher.register(path)
  watcher.release(path)

  data.listeners[path] = vim.loop.new_fs_event()

  data.listeners[path]:start(
    path,
    {},
    vim.schedule_wrap(function(error, filename, status)
      if status.rename then
        watcher.emit('rename', path, filename, error)
      elseif status.change then
        watcher.emit('change', path, filename, error)
      end
    end)
  )
end

function watcher.emit(event, ...)
  if type(data.events[event]) == 'function' then
    data.events[event](event, ...)
  end
end

function watcher.on(event, callback)
  if type(event) == 'table' then
    for _, event in ipairs(event) do
      data.events[event] = callback
    end
  else
    data.events[event] = callback
  end
end

function watcher.off(event)
  data.events[event] = nil
end

return watcher
