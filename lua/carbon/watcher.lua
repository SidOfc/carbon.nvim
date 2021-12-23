local watcher = { data = { listeners = {} }, events = {} }

function watcher.clear()
  for path in pairs(watcher.data.listeners) do
    watcher.release(path)
  end
end

function watcher.release(path)
  if watcher.data.listeners[path] then
    watcher.data.listeners[path]:stop()

    watcher.data.listeners[path] = nil
  end
end

function watcher.register(path)
  watcher.release(path)

  watcher.data.listeners[path] = vim.loop.new_fs_event()

  watcher.data.listeners[path]:start(
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
  if type(watcher.events[event]) == 'function' then
    watcher.events[event](event, ...)
  end
end

function watcher.on(event, callback)
  if type(event) == 'table' then
    for _, event in ipairs(event) do
      watcher.events[event] = callback
    end
  else
    watcher.events[event] = callback
  end
end

function watcher.off(event)
  watcher.events[event] = nil
end

return watcher
