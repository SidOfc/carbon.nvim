local util = require('carbon.util')
local buffer = require('carbon.buffer')
local actions = {}

function actions.edit()
  local entry = buffer.entry()

  if entry.is_directory then
    entry.is_open = not entry.is_open

    buffer.render()
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

function actions.explore()
  buffer.show()
end

function actions.up()
  if buffer.up() then
    vim.fn.cursor(1, 1)
    buffer.render()
  end
end

function actions.reset()
  if buffer.reset() then
    vim.fn.cursor(1, 1)
    buffer.render()
  end
end

function actions.down()
  if buffer.down() then
    vim.fn.cursor(1, 1)
    buffer.render()
  end
end

function actions.cd()
  if buffer.cd(vim.v.event.cwd) then
    vim.fn.cursor(1, 1)
    buffer.render()
  end
end

return actions
