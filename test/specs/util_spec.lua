local spy = require('luassert.spy')
local view = require('carbon.view')
local util = require('carbon.util')
local constants = require('carbon.constants')
local helpers = require('test.config.helpers')

describe('carbon.util', function()
  describe('get_line', function()
    it('returns the contents of given {lnum}', function()
      local expected = vim.api.nvim_buf_get_lines(0, 0, 1, true)[1]
      local received = util.get_line(1)

      assert.is.equal(expected, received)
    end)
  end)

  describe('explore_path', function()
    it('{path} is expanded to an absolute path', function()
      local cwd = vim.uv.cwd()
      local parent = cwd and vim.fs.dirname(cwd)

      assert.is.equal(parent, util.explore_path('../'))
      assert.is.equal(parent, util.explore_path('..'))
    end)

    it('{path} is expanded relative to {current_view}', function()
      local current_view = view.get(vim.fn.tempname())
      local parent = vim.fs.dirname(current_view.root.path)

      assert.is.equal(parent, util.explore_path('../', current_view))
      assert.is.equal(parent, util.explore_path('..', current_view))
    end)
  end)

  describe('cursor', function()
    it('{lnum} and {col} are both 1-based', function()
      util.cursor(2, 2)
      assert.is.same({ 2, 1 }, vim.api.nvim_win_get_cursor(0))
    end)
  end)

  describe('is_directory', function()
    it('returns true when {path} is a directory', function()
      assert.is_true(util.is_directory(vim.uv.cwd()))
    end)

    it('returns false when {path} is a file', function()
      assert.is_false(util.is_directory('README.md'))
    end)
  end)

  describe('extname', function()
    it('returns extension for a file with extension', function()
      assert.is.equal('txt', util.extname('file.txt'))
    end)

    it('returns nil for a file without', function()
      assert.is_nil(util.extname('file'))
    end)
  end)

  describe('relative_path', function()
    it('Makes an absolute path relative to provided {base}', function()
      local entry = helpers.entry('doc/assets') --[[@as carbon.entry.Entry]]
      local cwd = vim.uv.cwd() --[[@as string]]
      local relative_path = util.relative_path(entry.path, cwd)

      assert.is_true(vim.startswith(entry.path, cwd))
      assert.is_false(vim.startswith(relative_path, cwd))
      assert.is_false(vim.startswith(relative_path, '/'))
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
      assert.is.same(
        vim.api.nvim_get_current_win(),
        util.bufwinid(vim.api.nvim_get_current_buf())
      )
    end)
  end)

  describe('plug', function()
    it('returns <plug>(carbon-{name})', function()
      assert.is.equal('<plug>(carbon-test)', util.plug('test'))
    end)

    it('converts snake_case to kebab-case', function()
      assert.is.equal(
        '<plug>(carbon-snake-to-kebab)',
        util.plug('snake_to_kebab')
      )
    end)
  end)

  describe('tbl_key', function()
    it('returns key of {tbl} whose value equals {item}', function()
      assert.is.equal('b', util.tbl_key({ a = 1, b = 2, c = 3 }, 2))
    end)

    it('returns index of {tbl} whose value equals {item}', function()
      assert.is.equal(2, util.tbl_key({ 2, 4, 6 }, 4))
    end)
  end)

  describe('tbl_find', function()
    it('calls callback({value}, {key})', function()
      local callback = spy.new(function() end)

      util.tbl_find(
        { 2, 4, 6 },
        callback --[[@as fun(value: unknown, key: unknown): ...?]]
      )

      assert.spy(callback).was.called(3)
      assert.spy(callback).was.called_with(2, 1)
      assert.spy(callback).was.called_with(4, 2)
      assert.spy(callback).was.called_with(6, 3)
    end)

    it('returns {value}, {key} when found', function()
      local value, key = util.tbl_find({ 2, 4, 6 }, function(value)
        return value == 4
      end)

      assert.is.equal(4, value)
      assert.is.equal(2, key)
    end)

    it('returns nil when not found', function()
      assert.is_nil(util.tbl_find({}, function() end))
    end)
  end)

  describe('tbl_except', function()
    it('returns shallow copy of {tbl} with only {keys}', function()
      local tbl = { 1, 2, 3, a = 'a', b = 'b', c = '3' }

      assert.is.same({ 1, 2, 3 }, util.tbl_except(tbl, { 'a', 'b', 'c' }))
    end)
  end)

  describe('set_buf_mappings', function()
    it('sets {mappings} local to {buf}', function()
      assert.is.error(function()
        vim.keymap.del('n', '<c-z>', { buffer = 0 })
      end)

      util.set_buf_mappings(0, { { 'n', '<c-z>', function() end } })

      assert.is_not.error(function()
        vim.keymap.del('n', '<c-z>', { buffer = 0 })
      end)
    end)
  end)

  describe('command', function()
    it('creates user command', function()
      util.command('CreateCommandTest', function() end)

      assert.is_not_nil(vim.api.nvim_get_commands({}).CreateCommandTest)
    end)
  end)

  describe('highlight', function()
    it('creates highlight group', function()
      util.highlight('CreateHighlightTest', { link = 'Normal' })

      assert.is_not.same(
        0,
        vim.api.nvim_get_hl(constants.hl, { name = 'CreateHighlightTest' })
      )
    end)
  end)

  describe('autocmd', function()
    it('creates a buffer local autocommand', function()
      local scratch = util.create_scratch_buf()

      util.autocmd('FileAppendCmd', function() end, { buffer = scratch })

      local autocmd = helpers.autocmd('FileAppendCmd', { buffer = scratch })

      assert.is.same(scratch, autocmd.buffer)
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

      assert.is.same(scratch, autocmd.buffer)
      assert.is_true(autocmd.buflocal)

      vim.api.nvim_buf_delete(scratch, { force = true })
    end)
  end)

  describe('set_winhl', function()
    it('sets {highlights} local to {win}', function()
      local initial = vim.wo.winhl

      util.set_winhl(0, { FloatBorder = 'Normal' })

      assert.is_not.equal(initial, vim.wo.winhl)
      assert.is.same('FloatBorder:Normal', vim.wo.winhl)
    end)
  end)

  describe('create_scratch_buf', function()
    it('sets {options}.name', function()
      local scratch = util.create_scratch_buf({
        name = 'scratch-test',
      })

      assert.is.same(
        'scratch-test',
        vim.fs.basename(vim.api.nvim_buf_get_name(scratch))
      )

      vim.api.nvim_buf_delete(scratch, { force = true })
    end)

    it('sets {options}.lines', function()
      local scratch = util.create_scratch_buf({
        lines = { 'hello', 'world' },
      })

      assert.is.same(
        { 'hello', 'world' },
        vim.api.nvim_buf_get_lines(scratch, 0, -1, true)
      )

      vim.api.nvim_buf_delete(scratch, { force = true })
    end)

    it('sets {options}.mappings', function()
      local scratch = util.create_scratch_buf({
        mappings = { { 'n', '<c-z>', function() end } },
      })

      assert.is_not.error(function()
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
