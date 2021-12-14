local buffer = require('carbon.buffer')
local actions = {}

function actions.edit()
  local entry = buffer.entry()

  if entry.is_directory then
    entry.is_open = not entry.is_open

    buffer.draw()
  else
    vim.cmd('edit ' .. entry.path)
  end
end

function actions.split()
  local entry = buffer.entry()

  if not entry.is_directory then
    vim.cmd('split ' .. entry.path)
  end
end

function actions.vsplit()
  local entry = buffer.entry()

  if not entry.is_directory then
    vim.cmd('vsplit ' .. entry.path)
  end
end

function actions.select()
  local entry = buffer.entry()
  local parent = entry.parent

  entry.is_partial = false
  entry.is_selected = not entry.is_selected

  entry:update_children('is_partial', false, true)
  entry:update_children('is_selected', entry.is_selected, true)

  while parent do
    parent.is_partial = parent:has_selection()

    if not entry.is_selected then
      parent.is_selected = false
    end

    parent = parent.parent
  end

  buffer.draw()
end

function actions.explore()
  buffer.show()
end

return actions
