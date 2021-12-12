local handlers = {}
local buffer = require('carbon.buffer')

function handlers.move()
  print('TODO: carbon#handlers#move()')
end

function handlers.create()
  print('TODO: carbon#handlers#create()')
end

function handlers.destroy()
  print('TODO: carbon#handlers#destroy()')
end

function handlers.cursor()
  local entry = buffer.cursor_entry()

  if entry.is_directory then
    entry.is_open = not entry.is_open

    buffer.draw()
  else
    vim.cmd('edit ' .. entry.path)
  end
end

function handlers.hsplit()
  local entry = buffer.cursor_entry()

  if not entry.is_directory then
    vim.cmd('split ' .. entry.path)
  end
end

function handlers.vsplit()
  local entry = buffer.cursor_entry()

  if not entry.is_directory then
    vim.cmd('vsplit ' .. entry.path)
  end
end

return handlers
