local spy = require('luassert.spy')
local watcher = require('carbon.watcher')
local settings = require('carbon.settings')

describe('carbon.watcher', function()
  before_each(function()
    watcher.off()
    watcher.release()
  end)

  describe('on', function()
    it('registers {callback} for {event}', function()
      local callback = spy()

      watcher.on('test-event', callback)

      assert.is_true(watcher.has('test-event', callback))
    end)
  end)

  describe('emit', function()
    it('calls registered callbacks for {event}', function()
      local callback = spy()

      watcher.on('test-event', callback)
      watcher.emit('test-event')

      assert.spy(callback).is_called()
    end)

    it('always calls registered callbacks for "*"', function()
      local callback = spy()
      local callback2 = spy()

      watcher.on('*', callback)
      watcher.on('*', callback2)

      watcher.emit(os.clock() * math.random(1000))
      watcher.emit(os.clock() * math.random(1000))

      assert.spy(callback).is_called(2)
      assert.spy(callback2).is_called(2)
    end)

    it('triggers carbon:synchronize on new file', function()
      local callback = spy()

      watcher.register(vim.loop.cwd())
      watcher.on('carbon:synchronize', callback)

      vim.fn.system('touch check.txt')
      vim.wait(settings.sync_delay * 5)

      assert.spy(callback).is_called()
      assert
        .spy(callback)
        .is_called_with('carbon:synchronize', vim.loop.cwd(), 'check.txt', nil)
    end)

    it('triggers carbon:synchronize on new file', function()
      local callback = spy()

      vim.fn.system('touch check.sh')

      watcher.register(vim.loop.cwd())
      watcher.on('carbon:synchronize', callback)

      vim.fn.system('chmod +x check.sh')
      vim.wait(settings.sync_delay * 5)

      assert.spy(callback).is_called()
      assert
        .spy(callback)
        .is_called_with('carbon:synchronize', vim.loop.cwd(), 'check.sh', nil)
    end)

    it('triggers carbon:synchronize on new file', function()
      local callback = spy()

      vim.fn.system('touch check.sh')

      watcher.register(vim.loop.cwd())
      watcher.on('carbon:synchronize', callback)

      vim.fn.system('rm check.sh')
      vim.wait(settings.sync_delay * 5)

      assert.spy(callback).is_called()
      assert
        .spy(callback)
        .is_called_with('carbon:synchronize', vim.loop.cwd(), 'check.sh', nil)
    end)
  end)

  describe('off', function()
    it('clears {callback} for {event}', function()
      local callback = spy()

      watcher.on('test-event', callback)
      watcher.off('test-event', callback)

      assert.spy(callback).is_not_called()
      assert.is_false(watcher.has('test-event', callback))
    end)

    it('clears specific {callback} in specified {event}', function()
      local ignore = spy()
      local callback = spy()

      watcher.on('test-event', ignore)
      watcher.on('test-event', callback)
      watcher.off('test-event', ignore)
      watcher.emit('test-event')

      assert.spy(callback).is_called()
      assert.spy(ignore).is_not_called()
      assert.is_true(watcher.has('test-event', callback))
      assert.is_false(watcher.has('test-event', ignore))
    end)

    it('clears {event} when {callback} not specified', function()
      local keep = spy()
      local ignore = spy()
      local ignore2 = spy()

      watcher.on('event-1', keep)
      watcher.on('event-2', ignore)
      watcher.on('event-2', ignore2)
      watcher.off('event-2')
      watcher.emit('event-1')
      watcher.emit('event-2')

      assert.spy(keep).is_called()
      assert.spy(ignore).is_not_called()
      assert.spy(ignore2).is_not_called()
      assert.is_true(watcher.has('event-1', keep))
      assert.is_false(watcher.has('event-2', ignore))
      assert.is_false(watcher.has('event-2', ignore2))
    end)

    it('clears everything when called without arguments', function()
      local ignore = spy()
      local ignore2 = spy()

      watcher.on('event-1', ignore)
      watcher.on('event-2', ignore2)
      watcher.off()
      watcher.emit('event-1')
      watcher.emit('event-2')

      assert.spy(ignore).is_not_called()
      assert.spy(ignore2).is_not_called()
      assert.is_false(watcher.has('event-1', ignore))
      assert.is_false(watcher.has('event-2', ignore2))
    end)
  end)

  describe('has', function()
    it('returns true when {callback} registered in {event}', function()
      local callback = spy()

      watcher.on('test-event', callback)

      assert.is_true(watcher.has('test-event', callback))
    end)

    it('returns false when {callback} not registered in {event}', function()
      assert.is_false(watcher.has('test-event', spy()))
    end)
  end)

  describe('registered', function()
    it('returns a table of registered paths', function()
      watcher.register('test/specs')

      assert.is_same({ 'test/specs' }, watcher.registered())
    end)
  end)

  describe('keep', function()
    it('keeps registered path when {callback} returns true', function()
      watcher.register('lua')
      watcher.register('test/specs')

      watcher.keep(function(path)
        return vim.startswith(path, 'test')
      end)

      assert.is_same({ 'test/specs' }, watcher.registered())
    end)
  end)

  describe('register', function()
    it('registers {path}', function()
      watcher.register('lua')
      assert.is_same({ 'lua' }, watcher.registered())
    end)
  end)

  describe('release', function()
    it('releases {path}', function()
      watcher.register('lua')
      watcher.register('test/specs')
      watcher.release('lua')

      assert.is_same({ 'test/specs' }, watcher.registered())
    end)

    it('releases everything when {path} not specified', function()
      watcher.register('lua')
      watcher.register('test/specs')
      watcher.release()

      assert.is_same({}, watcher.registered())
    end)
  end)
end)
