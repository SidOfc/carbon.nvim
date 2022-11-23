require('test.config.assertions')

local spy = require('luassert.spy')
local util = require('carbon.util')
local entry = require('carbon.entry')
local carbon = require('carbon')
local buffer = require('carbon.buffer')
local watcher = require('carbon.watcher')
local settings = require('carbon.settings')
local helpers = require('test.config.helpers')

describe('carbon.buffer', function()
  before_each(function()
    carbon.explore()
    util.cursor(1, 1)
  end)

  describe('options', function()
    it('buffer has name "carbon"', function()
      assert.equal('carbon', vim.fn.bufname())
    end)

    it('buffer has filetype "carbon.explorer"', function()
      assert.equal('carbon.explorer', vim.o.filetype)
      assert.equal('carbon.explorer', vim.bo.filetype)
    end)

    it('is not modifiable', function()
      assert.is_false(vim.bo.modifiable)
    end)

    it('is not modified', function()
      assert.is_false(vim.bo.modified)
    end)
  end)

  describe('autocommands', function()
    it('calls buffer.process_enter on BufWinEnter', function()
      local callback = spy.on(buffer, 'process_enter')

      vim.api.nvim_exec_autocmds('BufWinEnter', { buffer = 0 })

      assert.spy(callback).is_called()
    end)

    it('calls buffer.process_hidden on BufHidden', function()
      local callback = spy.on(buffer, 'process_hidden')

      vim.api.nvim_exec_autocmds('BufHidden', { buffer = 0 })

      assert.spy(callback).is_called()
    end)
  end)

  describe('keymaps', function()
    for action, maps in pairs(settings.actions) do
      local plug = util.plug(action)
      local keys = type(maps) == 'string' and { maps } or maps

      for _, key in ipairs(keys) do
        it(string.format('binds %s to %s', key, plug), function()
          assert.same(string.lower(vim.fn.maparg(key, 'n')), plug)
        end)
      end
    end
  end)

  describe('display', function()
    it('shows current directory', function()
      assert.same({
        vim.fn.fnamemodify(vim.loop.cwd(), ':t') .. '/',
        '  .github/workflows/ci.yml',
        '  dev/init.lua',
        '+ doc/',
        '+ lua/',
        '  plugin/carbon.vim',
        '+ test/',
        '  .gitignore',
        '  .luacheckrc',
        '  LICENSE.md',
        '  Makefile',
        '  README.md',
        '  stylua.toml',
      }, vim.api.nvim_buf_get_lines(0, 0, -1, true))
    end)
  end)

  describe('is_loaded', function()
    it('returns true when buffer is loaded', function()
      assert.is_true(buffer.is_loaded())
    end)

    it('returns false when buffer is not loaded', function()
      local bufnr = vim.api.nvim_get_current_buf()

      vim.cmd.edit('README.md')
      vim.api.nvim_buf_delete(bufnr, { force = true })

      assert.is_false(buffer.is_loaded())
    end)
  end)

  describe('is_hidden', function()
    it('returns false when buffer is not hidden', function()
      assert.is_false(buffer.is_hidden())
    end)

    it('returns true when buffer is hidden', function()
      vim.cmd.edit('README.md')

      assert.is_true(buffer.is_hidden())
    end)
  end)

  describe('handle', function()
    it('returns current buffer handle if loaded', function()
      assert.equal(vim.api.nvim_get_current_buf(), buffer.handle())
    end)

    it('creates and returns new buffer handle if not loaded', function()
      local bufnr = vim.api.nvim_get_current_buf()

      vim.cmd.edit('README.md')
      vim.api.nvim_buf_delete(bufnr, { force = true })

      assert.not_equal(bufnr, buffer.handle())
    end)
  end)

  describe('show', function()
    it('replaces current buffer with carbon buffer', function()
      vim.cmd.edit('README.md')

      local bufnr = vim.api.nvim_get_current_buf()

      buffer.show()

      assert.equal('carbon', vim.fn.bufname())
      assert.not_equal(bufnr, vim.api.nvim_get_current_buf())
    end)

    it('rerenders the buffer', function()
      local render = spy.on(buffer, 'render')

      buffer.show()

      assert.spy(render).is_called()
    end)
  end)

  describe('render', function()
    it('does nothing when buffer is not loaded', function()
      local bufnr = vim.api.nvim_get_current_buf()

      vim.cmd.edit('README.md')
      vim.api.nvim_buf_delete(bufnr, { force = true })

      assert.is_nil(buffer.render())
    end)

    it('does nothing when buffer is hidden', function()
      vim.cmd.edit('README.md')

      assert.is_nil(buffer.render())
    end)

    describe('always_reveal', function()
      it('calls focus_flash when enabled', function()
        local focus_flash = spy.on(buffer, 'focus_flash')
        local lua_entry = entry.find(helpers.resolve('lua'))
        local lua_carbon_entry = entry.find(helpers.resolve('lua'))
        local target_path = helpers.resolve('lua/carbon/util.lua')

        settings.always_reveal = true

        buffer.expand_to_path(target_path)
        buffer.render()
        vim.wait(settings.flash.delay * 3)

        assert.spy(focus_flash).is_called()
        assert.equal(target_path, buffer.cursor().line.entry.path)

        lua_entry:set_open(false)
        lua_carbon_entry:set_open(false)
        settings.always_reveal = settings.defaults.always_reveal
      end)
    end)
  end)

  describe('expand_to_path', function()
    it('does nothing when target outside of cwd', function()
      assert.is_nil(buffer.expand_to_path('/'))
    end)

    it('opens parent directories', function()
      local lua_entry = entry.find(helpers.resolve('lua'))
      local lua_carbon_entry = entry.find(helpers.resolve('lua'))

      assert.is_false(lua_entry:is_open())
      assert.is_false(lua_carbon_entry:is_open())

      buffer.expand_to_path(helpers.resolve('lua/carbon/util.lua'))

      assert.is_true(lua_entry:is_open())
      assert.is_true(lua_carbon_entry:is_open())
    end)

    it('moves the cursor to the revealed entry', function()
      local target_path = helpers.resolve('lua/carbon/util.lua')

      buffer.expand_to_path(target_path)
      buffer.render()

      assert.equal(target_path, buffer.cursor().line.entry.path)
    end)
  end)

  describe('cursor', function()
    it('returns line information of current line', function()
      util.cursor(3, 1)

      assert.equal(3, buffer.cursor().line.lnum)
    end)

    it('returns target entry with count', function()
      local result

      vim.keymap.set('n', '_', function()
        result = buffer.cursor()
      end, { buffer = 0 })

      util.cursor(3, 1)
      helpers.type_keys('1_')

      vim.keymap.del('n', '_', { buffer = 0 })

      assert.equal(helpers.resolve('dev'), result.target.path)
    end)
  end)

  describe('lines', function()
    it('returns a table of line info objects', function()
      for _, line_info in ipairs(buffer.lines()) do
        assert.is_table(line_info)
        assert.is_number(line_info.lnum)
        assert.is_number(line_info.depth)
        assert.is_entry(line_info.entry)
        assert.is_string(line_info.line)
        assert.is_table(line_info.highlights)
        assert.is_table(line_info.path)
      end
    end)
  end)

  describe('set_root', function()
    it('accepts string path', function()
      local target_path = helpers.resolve('lua')

      assert.equal(target_path, buffer.set_root(target_path).path)
      assert.is_true(buffer.reset())
    end)

    it('accepts carbon.entry.new instance', function()
      local target_entry = entry.new(helpers.resolve('lua'))

      assert.equal(target_entry.path, buffer.set_root(target_entry).path)
      assert.is_true(buffer.reset())
    end)

    it('filters watchers', function()
      local watchers = watcher.registered()

      buffer.set_root(helpers.resolve('lua'))

      assert.not_same(watchers, watcher.registered())
      assert.is_true(buffer.reset())
    end)

    describe('sync_pwd', function()
      it("sets Neovim's cwd when enabled", function()
        local cwd = vim.loop.cwd()

        settings.sync_pwd = true

        buffer.set_root(helpers.resolve('lua'))

        settings.sync_pwd = settings.defaults.sync_pwd

        assert.not_same(cwd, vim.loop.cwd())
        assert.is_true(buffer.reset())
      end)

      it("does not set Neovim's cwd when disabled", function()
        local cwd = vim.loop.cwd()

        buffer.set_root(helpers.resolve('lua'))

        assert.same(cwd, vim.loop.cwd())
        assert.is_true(buffer.reset())
      end)
    end)
  end)

  describe('reset', function()
    describe('sync_pwd', function()
      it("resets Neovim's cwd when enabled", function()
        local cwd = vim.loop.cwd()

        settings.sync_pwd = true

        buffer.set_root(helpers.resolve('lua'))

        settings.sync_pwd = settings.defaults.sync_pwd

        assert.not_same(cwd, vim.loop.cwd())
        assert.is_true(buffer.reset())
        assert.same(cwd, vim.loop.cwd())
      end)

      it("resets Neovim's cwd when disabled", function()
        local cwd = vim.loop.cwd()

        settings.sync_pwd = true

        buffer.set_root(helpers.resolve('lua'))

        settings.sync_pwd = false

        assert.not_same(cwd, vim.loop.cwd())
        assert.is_true(buffer.reset())
        assert.same(cwd, vim.loop.cwd())

        settings.sync_pwd = settings.defaults.sync_pwd
      end)
    end)
  end)

  describe('set_lines', function()
    it('overwrites buffer content', function()
      buffer.set_lines(0, 0, { 'a', 'b', 'c' })

      assert.same({ 'a', 'b', 'c' }, vim.api.nvim_buf_get_lines(0, 0, 3, true))
    end)

    it('works when modifiable is false', function()
      assert.is_false(vim.bo.modifiable)
      buffer.set_lines(0, 0, { 'a', 'b', 'c' })

      assert.same({ 'a', 'b', 'c' }, vim.api.nvim_buf_get_lines(0, 0, 3, true))
    end)

    it('resets modifiable when not in insert', function()
      buffer.set_lines(0, 0, { 'a', 'b', 'c' })
      assert.is_false(vim.bo.modifiable)
    end)

    it('does not set modified', function()
      buffer.set_lines(0, 0, { 'a', 'b', 'c' })
      assert.is_false(vim.bo.modified)
    end)
  end)

  -- FIXME: fs events have wildly inconsistent timing, causing
  --        tests below to fail often while actually working well
  --        in isolated scenarios. Because of this, all tests
  --        below have been marked "pending" until a solution is found.

  describe('create', function()
    pending('can create file', function()
      helpers.type_keys(
        string.format('%shello.txt<cr>', settings.actions.create)
      )

      assert.is_true(helpers.has_path('hello.txt'))
    end)

    pending('can create directory', function()
      helpers.type_keys(string.format('%shello/<cr>', settings.actions.create))

      assert.is_true(helpers.has_path('hello/'))
      assert.is_true(helpers.is_directory('hello/'))
    end)

    pending('can create deeply nested path', function()
      helpers.type_keys(
        string.format('%shello/world/test.txt<cr>', settings.actions.create)
      )

      assert.is_true(helpers.has_path('hello/world/test.txt'))
    end)
  end)

  describe('delete', function()
    pending('can delete file', function()
      helpers.ensure_path('.a/.a.txt')

      util.cursor(2, 1)
      helpers.type_keys(string.format('%sD', settings.actions.delete))

      assert.is_true(helpers.has_path('.a/'))
      assert.is_false(helpers.has_path('.a/.a.txt'))
    end)

    pending('can delete directory', function()
      helpers.ensure_path('.a/')

      util.cursor(2, 1)
      helpers.type_keys(string.format('%sD', settings.actions.delete))

      assert.is_false(helpers.has_path('.a/'))
    end)

    pending('can partially delete deeply nested path using count', function()
      helpers.ensure_path('.a/.a/a.txt')
      util.cursor(2, 1)
      helpers.type_keys(string.format('2%sD', settings.actions.delete))

      assert.is_true(helpers.has_path('.a/'))
      assert.is_false(helpers.has_path('.a/.a/'))
    end)

    pending('can completely delete deeply nested path using count', function()
      helpers.ensure_path('.a/.a/.a.txt')
      util.cursor(2, 1)
      helpers.type_keys(string.format('1%sD', settings.actions.delete))

      assert.is_false(helpers.has_path('.a/'))
    end)
  end)

  describe('move', function()
    pending('can rename path', function()
      helpers.ensure_path('.a/.a.txt')

      util.cursor(2, 1)
      helpers.type_keys(string.format('%s1<cr>', settings.actions.move))

      assert.is_false(helpers.has_path('.a/.a.txt'))
      assert.is_true(helpers.has_path('.a/.a.txt1'))

      helpers.delete_path('.a/')
    end)

    pending('creates intermediate directories', function()
      helpers.ensure_path('.a/.a.txt')

      util.cursor(2, 1)
      helpers.type_keys(
        string.format('%s<bs><bs><bs><bs>/b/c<cr>', settings.actions.move)
      )

      assert.is_false(helpers.has_path('.a/.a/.a.txt'))
      assert.is_true(helpers.has_path('.a/.a/b/c'))
    end)
  end)
end)
