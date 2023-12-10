require('test.config.assertions')

local spy = require('luassert.spy')
local view = require('carbon.view')
local util = require('carbon.util')
local helpers = require('test.config.helpers')

describe('carbon.util', function()
  describe('get_line', function()
    it('returns the contents of given {lnum}', function()
      local expected = vim.fn.getline(1)
      local received = util.get_line(1)

      assert.equal(expected, received)
    end)
  end)

  describe('explore_path', function()
    it('{path} is expanded to an absolute path', function()
      local cwd = vim.loop.cwd()
      local parent = vim.fn.fnamemodify(cwd, ':h')

      assert.equal(parent, util.explore_path('../'))
      assert.equal(parent, util.explore_path('..'))
    end)

    it('{path} is expanded relative to {current_view}', function()
      local current_view = view.get(vim.fn.tempname())
      local parent = vim.fn.fnamemodify(current_view.root.path, ':h')

      assert.equal(parent, util.explore_path('../', current_view))
      assert.equal(parent, util.explore_path('..', current_view))
    end)
  end)

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

  describe('is_excluded', function()
    it('returns true when {path} in settings.exclude', function()
      assert.is_true(util.is_excluded('/some/node_modules/package'))
    end)

    it('returns false when {path} in settings.exclude', function()
      assert.is_false(util.is_excluded('/some/random/path'))
    end)
  end)

  describe('bufwinid', function()
    it('returns window id of {buf}', function()
      assert.same(
        vim.fn.win_getid(),
        util.bufwinid(vim.api.nvim_get_current_buf())
      )
    end)
  end)

  describe('plug', function()
    it('returns <plug>(carbon-{name})', function()
      assert.equal('<plug>(carbon-test)', util.plug('test'))
    end)

    it('converts snake_case to kebab-case', function()
      assert.equal('<plug>(carbon-snake-to-kebab)', util.plug('snake_to_kebab'))
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
      assert.error(function()
        vim.keymap.del('n', '<c-z>', { buffer = 0 })
      end)

      util.set_buf_mappings(0, { { 'n', '<c-z>', function() end } })

      assert.not_error(function()
        vim.keymap.del('n', '<c-z>', { buffer = 0 })
      end)
    end)
  end)

  describe('command', function()
    it('creates user command', function()
      util.command('CreateCommandTest', function() end)

      assert.not_nil(vim.api.nvim_get_commands({}).CreateCommandTest)
    end)
  end)

  describe('highlight', function()
    it('creates highlight group', function()
      util.highlight('CreateHighlightTest', { link = 'Normal' })

      assert.not_same(0, vim.fn.hlID('CreateHighlightTest'))
    end)
  end)

  describe('autocmd', function()
    it('creates a buffer local autocommand', function()
      local scratch = util.create_scratch_buf()

      util.autocmd('FileAppendCmd', function() end, { buffer = scratch })

      local autocmd = helpers.autocmd('FileAppendCmd', { buffer = scratch })

      assert.same(scratch, autocmd.buffer)
      assert.is_true(autocmd.buflocal)

      vim.api.nvim_buf_delete(scratch, { force = true })
    end)
  end)

  describe('clear_autocmd', function()
    it('clears a buffer local autocmd', function()
      local scratch = util.create_scratch_buf()

      util.autocmd('FileAppendCmd', function() end, { buffer = scratch })
      util.clear_autocmd('FileAppendCmd', { buffer = scratch })

      local autocmd = helpers.autocmd('FileAppendCmd', { buffer = scratch })

      assert.is_nil(autocmd.buffer)
      assert.is_nil(autocmd.buflocal)

      vim.api.nvim_buf_delete(scratch, { force = true })
    end)
  end)

  describe('set_buf_autocmds', function()
    it('sets {autocmds} local to {buf}', function()
      local scratch = util.create_scratch_buf()

      util.set_buf_autocmds(scratch, { FileAppendCmd = function() end })

      local autocmd = helpers.autocmd('FileAppendCmd', { buffer = scratch })

      assert.same(scratch, autocmd.buffer)
      assert.is_true(autocmd.buflocal)

      vim.api.nvim_buf_delete(scratch, { force = true })
    end)
  end)

  describe('set_winhl', function()
    it('sets {highlights} local to {win}', function()
      local initial = vim.wo.winhl

      util.set_winhl(0, { FloatBorder = 'Normal' })

      assert.not_equal(initial, vim.wo.winhl)
      assert.same('FloatBorder:Normal', vim.wo.winhl)
    end)
  end)

  describe('create_scratch_buf', function()
    it('sets {options}.name', function()
      local scratch = util.create_scratch_buf({
        name = 'scratch-test',
      })

      assert.is_same(
        'scratch-test',
        vim.fn.fnamemodify(vim.api.nvim_buf_get_name(scratch), ':t')
      )

      vim.api.nvim_buf_delete(scratch, { force = true })
    end)

    it('sets {options}.lines', function()
      local scratch = util.create_scratch_buf({
        lines = { 'hello', 'world' },
      })

      assert.same(
        { 'hello', 'world' },
        vim.api.nvim_buf_get_lines(scratch, 0, -1, true)
      )

      vim.api.nvim_buf_delete(scratch, { force = true })
    end)

    it('sets {options}.mappings', function()
      local scratch = util.create_scratch_buf({
        mappings = { { 'n', '<c-z>', function() end } },
      })

      assert.not_error(function()
        vim.keymap.del('n', '<c-z>', { buffer = scratch })
      end)

      vim.api.nvim_buf_delete(scratch, { force = true })
    end)

    it('sets {options}.autocmds', function()
      local scratch = util.create_scratch_buf({
        autocmds = {
          FileAppendCmd = function() end,
        },
      })

      local autocmd = helpers.autocmd('FileAppendCmd', { buffer = scratch })

      assert.is_number(autocmd.id)

      vim.api.nvim_buf_delete(scratch, { force = true })
    end)
  end)
end)
