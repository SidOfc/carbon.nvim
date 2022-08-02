local spy = require('luassert.spy')
local util = require('carbon.util')

describe('carbon.util', function()
  describe('cursor', function()
    it('{lnum} and {col} are both 1-based', function()
      util.cursor(2, 2)

      assert.equal(2, vim.fn.line('.'))
      assert.equal(2, vim.fn.col('.'))
    end)
  end)

  describe('is_directory', function()
    it('returns true when {path} is a directory', function()
      assert.is_true(util.is_directory(vim.loop.cwd()))
    end)

    it('returns false when {path} is a file', function()
      assert.is_false(util.is_directory('README.md'))
    end)
  end)

  describe('plug', function()
    it('returns <plug>(carbon-{name})', function()
      assert.equal('<plug>(carbon-test)', util.plug('test'))
    end)
  end)

  describe('tbl_key', function()
    it('returns key of {tbl} whose value equals {item}', function()
      assert.equal('b', util.tbl_key({ a = 1, b = 2, c = 3 }, 2))
    end)

    it('returns index of {tbl} whose value equals {item}', function()
      assert.equal(2, util.tbl_key({ 2, 4, 6 }, 4))
    end)
  end)

  describe('tbl_find', function()
    it('calls callback({value}, {key})', function()
      local callback = spy()

      util.tbl_find({ 2, 4, 6 }, callback)

      assert.spy(callback).is_called(3)
      assert.spy(callback).is_called_with(2, 1)
      assert.spy(callback).is_called_with(4, 2)
      assert.spy(callback).is_called_with(6, 3)
    end)

    it('returns {value}, {key} when found', function()
      local value, key = util.tbl_find({ 2, 4, 6 }, function(value)
        return value == 4
      end)

      assert.equal(4, value)
      assert.equal(2, key)
    end)

    it('returns nil when not found', function()
      assert.is_nil(util.tbl_find({}, function() end))
    end)
  end)

  describe('tbl_except', function()
    it('returns shallow copy of {tbl} with only {keys}', function()
      local tbl = { 1, 2, 3, a = 'a', b = 'b', c = '3' }

      assert.same({ 1, 2, 3 }, util.tbl_except(tbl, { 'a', 'b', 'c' }))
    end)
  end)

  describe('set_buf_mappings', function()
    it('sets {mappings} local to {buf}', function()
      local function unmap()
        vim.keymap.del('n', '<c-z>', { buffer = 0 })
      end

      assert.error(unmap)

      util.set_buf_mappings(0, { { 'n', '<c-z>', function() end } })

      assert.not_error(unmap)
      assert.error(unmap)
    end)
  end)

  describe('set_winhl', function()
    it('sets {highlights} local to {win}', function()
      local initial = vim.wo.winhl

      util.set_winhl(0, { FloatBorder = 'Normal' })

      assert.not_equal(initial, vim.wo.winhl)
    end)
  end)
end)
