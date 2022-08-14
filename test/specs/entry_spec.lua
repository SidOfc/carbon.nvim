require('test.config.assertions')

local spy = require('luassert.spy')
local util = require('carbon.util')
local entry = require('carbon.entry')
local watcher = require('carbon.watcher')
local helpers = require('test.config.helpers')

describe('entry', function()
  describe('new', function()
    it('returns table with metatable of carbon.entry', function()
      assert.is_entry(entry.new(helpers.resolve('lua')))
    end)

    it('path property is absolute path', function()
      local absolute_path = helpers.resolve('lua')

      assert.equal(absolute_path, entry.new(absolute_path).path)
    end)

    it('name property is filename of path', function()
      local absolute_path = helpers.resolve('lua')
      local filename = vim.fn.fnamemodify(absolute_path, ':t')

      assert.equal(filename, entry.new(absolute_path).name)
    end)

    it('is_directory is boolean', function()
      assert.is_boolean(entry.new(helpers.resolve('lua')).is_directory)
    end)

    it('is_executable is boolean', function()
      assert.is_boolean(entry.new(helpers.resolve('lua')).is_executable)
    end)

    it('is_symlink is false when not symlink', function()
      assert.is_false(entry.new(helpers.resolve('lua')).is_symlink)
    end)

    it('is_symlink is number 1 when valid symlink', function()
      local original = helpers.resolve('README.md')
      local symlink = string.format('%s-symlink', original)

      vim.loop.fs_symlink(original, symlink)

      assert.equal(1, entry.new(symlink).is_symlink)

      vim.fn.delete(symlink)
    end)

    it('is_symlink is number 2 when broken symlink', function()
      local original = helpers.resolve('README.md')
      local broken = string.format('%s-broken', original)
      local symlink = string.format('%s-symlink', original)

      vim.loop.fs_symlink(broken, symlink)

      assert.equal(2, entry.new(symlink).is_symlink)

      vim.fn.delete(symlink)
    end)
  end)

  describe('find', function()
    it('returns loaded children', function()
      assert.is_entry(entry.find(helpers.resolve('lua')))
    end)

    it('returns nil for not loaded children', function()
      assert.is_nil(entry.find(helpers.resolve(tostring(os.clock()))))
    end)
  end)

  describe('synchronize', function()
    it('does nothing when called on regular file', function()
      local file = entry.new(helpers.resolve('README.md'))
      local file_synchronize = spy.on(file, 'synchronize')

      file:synchronize()
      assert.spy(file_synchronize).is_called(1)
    end)

    it('calls synchronize recursively on directory', function()
      local lua = entry.find(helpers.resolve('lua'))
      local lua_carbon = entry.find(helpers.resolve('lua/carbon'))
      local lua_synchronize = spy.on(lua, 'synchronize')
      local lua_carbon_synchronize = spy.on(lua_carbon, 'synchronize')

      lua:synchronize()
      assert.spy(lua_synchronize).is_called()
      assert.spy(lua_carbon_synchronize).is_called()
    end)
  end)

  describe('terminate', function()
    it('releases from watcher', function()
      local watcher_release = spy.on(watcher, 'release')
      local target_path = helpers.resolve('README.md')

      entry.find(target_path):terminate()

      assert.spy(watcher_release).is_called_with(target_path)
    end)

    it('sets children to nil on directory', function()
      helpers.ensure_path('a/b/c/')
      local target = entry.new(helpers.resolve('a/b/c/'))
      target:children()

      assert.is_true(target:has_children())

      target:terminate()

      assert.is_false(target:has_children())
      helpers.delete_path('a/')
    end)

    it('removes itself from parent', function()
      helpers.ensure_path('a/b/c.txt')
      local parent = entry.new(helpers.resolve('a/'))
      local target = parent:children()[1]

      assert.is_entry(target)

      target:terminate()

      assert.is_nil(util.tbl_find(parent:children(), function(child)
        return child.path == target.path
      end))

      helpers.delete_path('a/')
    end)
  end)

  describe('is_compressible', function()
    it('is boolean', function()
      local target = entry.new(helpers.resolve('lua'))

      assert.is_boolean(target:is_compressible())
    end)

    it('is true by default', function()
      local target = entry.new(helpers.resolve('lua'))

      target:set_compressible(nil)

      assert.is_true(target:is_compressible())
    end)
  end)

  describe('set_compressible', function()
    it('sets compressible status', function()
      local target = entry.new(helpers.resolve('lua'))

      target:set_compressible(false)

      assert.is_false(target:is_compressible())

      target:set_compressible(nil)
    end)
  end)

  describe('is_open', function()
    it('is boolean', function()
      local target = entry.new(helpers.resolve('lua'))

      assert.is_boolean(target:is_open())
    end)

    it('is false by default', function()
      local target = entry.new(helpers.resolve('lua'))

      assert.is_false(target:is_open())
    end)
  end)

  describe('set_open', function()
    it('does nothing when called on regular file', function()
      local file = entry.new(helpers.resolve('README.md'))

      file:set_open(true)

      assert.is_false(file:is_open())
    end)

    it('sets opened status', function()
      local target = entry.new(helpers.resolve('lua'))

      target:set_open(true)

      assert.is_true(target:is_open())

      target:set_open(nil)
    end)

    it('opens recursively when recursive is true', function()
      local target = entry.new(helpers.resolve('lua'))
      local dirs = vim.tbl_filter(function(child)
        return child.is_directory
      end, target:children())

      assert.is_true(#dirs > 0)

      target:set_open(true, true)

      assert.is_true(target:is_open())

      for _, dir_child in ipairs(dirs) do
        assert.is_true(dir_child:is_open())
      end

      target:set_open(nil, true)

      assert.is_false(target:is_open())

      for _, dir_child in ipairs(dirs) do
        assert.is_false(dir_child:is_open())
      end
    end)
  end)

  describe('children', function()
    it('returns empty table on regular file', function()
      local file = entry.new(helpers.resolve('README.md'))

      assert.same({}, file:children())
    end)

    it('returns children of directory', function()
      helpers.ensure_path('a/b.txt')
      helpers.ensure_path('a/c.txt')

      local dir = entry.new(helpers.resolve('a/'))

      dir:set_children(nil)
      assert.is_true(#dir:children() > 0)

      helpers.delete_path('a/')
    end)

    it('calls get_children if directory and not has_children', function()
      helpers.ensure_path('a/b/c.txt')

      local dir = entry.new(helpers.resolve('a/'))
      local dir_has_children = spy.on(dir, 'has_children')

      dir:set_children(nil)
      dir:children()

      assert.spy(dir_has_children).is_called(1)

      helpers.delete_path('a/')
    end)
  end)

  describe('has_children', function()
    it('returns true when children loaded', function()
      helpers.ensure_path('a/b/c.txt')

      local dir = entry.new(helpers.resolve('a/'))

      dir:children()
      assert.is_true(dir:has_children())

      helpers.delete_path('a/')
    end)

    it('returns false when children not loaded', function()
      helpers.ensure_path('a/b/c.txt')

      local dir = entry.new(helpers.resolve('a/'))

      dir:set_children(nil)
      assert.is_false(dir:has_children())

      helpers.delete_path('a/')
    end)
  end)

  describe('set_children', function()
    it('sets children', function()
      helpers.ensure_path('a/b/c.txt')

      local dir = entry.new(helpers.resolve('a/'))
      local children = { 'test' }

      dir:set_children(children)

      assert.equal(children, dir:children())

      helpers.delete_path('a/')
    end)
  end)

  describe('get_children', function()
    it('gets children', function()
      helpers.ensure_path('a/b/c.txt')

      local dir = entry.new(helpers.resolve('a/'))

      assert.is_equal(1, #dir:get_children())

      helpers.delete_path('a/')
    end)

    it('does not set children', function()
      helpers.ensure_path('a/b/c.txt')

      local dir = entry.new(helpers.resolve('a/'))

      dir:set_children(nil)
      dir:get_children()

      assert.is_false(dir:has_children())

      helpers.delete_path('a/')
    end)
  end)
end)
