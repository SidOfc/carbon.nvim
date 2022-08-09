local spy = require('luassert.spy')
local watcher = require('carbon.watcher')

describe('carbon.watcher', function()
  it('calls registered callback for some event', function()
    local callback = spy()

    watcher.on('test-event', callback)
    watcher.emit('test-event')

    assert.spy(callback).is_called()
  end)
end)
