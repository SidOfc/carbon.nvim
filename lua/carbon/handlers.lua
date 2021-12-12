local buffer = require('carbon.buffer')
local handlers = {}

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

function handlers.toggle()
  local entry = buffer.cursor_entry()
  local parent = entry.parent()

  entry.is_partial = false
  entry.is_selected = not entry.is_selected

  entry.set_children('is_partial', false, true)
  entry.set_children('is_selected', entry.is_selected, true)

  while parent do
    parent.is_partial = parent.has_selected_or_partial_children()

    if not entry.is_selected then
      parent.is_selected = false
    end

    parent = parent.parent()
  end

  buffer.draw()
end

return handlers
