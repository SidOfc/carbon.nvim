local util = require('carbon.util')
local carbon = require('carbon')
local buffer = require('carbon.buffer')
local watcher = require('carbon.watcher')
local settings = require('carbon.settings')
local helpers = require('test.config.helpers')

describe('carbon', function()
  before_each(function()
    carbon.explore()
    util.cursor(1, 1)
  end)

  describe('autocommands', function()
    describe('DirChanged', function()
      it('exists', function()
        local autocmd = helpers.autocmd('DirChanged')

        assert.is_number(autocmd.id)
      end)

      it('is not buffer local', function()
        local autocmd = helpers.autocmd('DirChanged')

        assert.is_false(autocmd.buflocal)
      end)

      it('pattern is global', function()
        local autocmd = helpers.autocmd('DirChanged')

        assert.same('global', autocmd.pattern)
      end)
    end)

    describe('BufWinEnter', function()
      it('exists', function()
        local autocmd = helpers.autocmd('BufWinEnter')

        assert.is_number(autocmd.id)
      end)

      it('is buffer local', function()
        local autocmd = helpers.autocmd('BufWinEnter')

        assert.is_true(autocmd.buflocal)
      end)
    end)

    describe('BufHidden', function()
      it('exists', function()
        local autocmd = helpers.autocmd('BufHidden')

        assert.is_number(autocmd.id)
      end)

      it('is buffer local', function()
        local autocmd = helpers.autocmd('BufHidden')

        assert.is_true(autocmd.buflocal)
      end)
    end)
  end)

  describe('keymaps', function()
    for action in pairs(settings.actions) do
      local plug = util.plug(action)

      it(string.format('binds %s to carbon.%s()', plug, action), function()
        assert.is_number(
          string.find(string.lower(vim.fn.maparg(plug, 'n')), '<lua %w+')
        )
      end)
    end
  end)

  describe('setup', function()
    it('does not merge settings after initialization', function()
      assert.is_nil(carbon.setup({ actions = false, highlights = false }))

      assert.equal(
        vim.inspect(settings.defaults.actions),
        vim.inspect(settings.actions)
      )

      assert.equal(
        vim.inspect(settings.defaults.highlights),
        vim.inspect(settings.highlights)
      )
    end)
  end)

  describe('edit', function()
    it('toggles directory when on directory', function()
      local doc_entry = helpers.entry('doc')

      util.cursor(4, 1)
      carbon.edit()

      assert.is_true(doc_entry:is_open())

      carbon.edit()
      assert.is_false(doc_entry:is_open())
    end)

    it('edits file when on file', function()
      assert.equal('carbon', vim.fn.bufname())

      util.cursor(12, 1)
      carbon.edit()

      assert.not_equal('carbon', vim.fn.bufname())
    end)
  end)

  describe('split', function()
    it('open file in horizontal split', function()
      assert.equal('carbon', vim.fn.bufname())

      util.cursor(3, 1)
      carbon.split()

      assert.not_equal('carbon', vim.fn.bufname())

      vim.cmd.wincmd('j')

      assert.equal('carbon', vim.fn.bufname())
    end)
  end)

  describe('vsplit', function()
    it('open file in vertical split', function()
      assert.equal('carbon', vim.fn.bufname())

      util.cursor(3, 1)
      carbon.vsplit()

      assert.not_equal('carbon', vim.fn.bufname())

      vim.cmd.wincmd('l')

      assert.equal('carbon', vim.fn.bufname())
    end)
  end)

  describe('toggle_recursive', function()
    it('toggles recursively opened directory', function()
      local assets_entry = helpers.entry('doc/assets')

      util.cursor(4, 1)
      assert.not_nil(assets_entry)

      carbon.toggle_recursive()
      assert.is_true(assets_entry:is_open())
      assert.same(
        { '- doc/', '  - assets/' },
        vim.api.nvim_buf_get_lines(0, 3, 5, true)
      )

      carbon.toggle_recursive()
      assert.is_false(assets_entry:is_open())
      assert.same(
        { '+ doc/', '+ lua/' },
        vim.api.nvim_buf_get_lines(0, 3, 5, true)
      )
    end)
  end)

  describe('explore', function()
    it('shows the buffer', function()
      util.cursor(12, 1)
      carbon.edit()
      carbon.explore()

      assert.equal('carbon', vim.fn.bufname())
    end)
  end)

  describe('explore_left', function()
    it('shows the buffer to the left of the current buffer', function()
      util.cursor(12, 1)
      carbon.edit()

      local before_bufname = vim.fn.bufname()

      carbon.explore_left()
      vim.cmd.wincmd('l')

      assert.equal(before_bufname, vim.fn.bufname())

      vim.cmd.bdelete()
    end)
  end)

  describe('explore_float', function()
    it('shows the buffer in a floating window', function()
      carbon.explore_float()

      assert.is_number(
        vim.api.nvim_win_get_config(vim.api.nvim_get_current_win()).zindex
      )

      vim.cmd.close()
    end)
  end)

  describe('up', function()
    it('sets cwd to parent directory', function()
      local original_cwd = vim.loop.cwd()

      settings.sync_pwd = true
      carbon.up()

      assert.equal(vim.loop.cwd(), vim.fn.fnamemodify(original_cwd, ':h'))

      carbon.reset()
      settings.sync_pwd = settings.defaults.sync_pwd
    end)

    it('registers new directory listeners', function()
      local original_listeners = watcher.registered()

      carbon.up()

      assert.not_same(original_listeners, watcher.registered())
    end)

    it('automatically opens previous cwd', function()
      util.cursor(1, 1)

      assert.is_equal('carbon', vim.fn.bufname())

      local root_entry = buffer.cursor().line.entry

      carbon.up()

      assert.is_true(root_entry:is_open())

      carbon.reset()
    end)
  end)

  describe('reset', function()
    it('reset to original cwd during startup', function()
      local original_cwd = vim.loop.cwd()

      settings.sync_pwd = true
      carbon.up()
      carbon.reset()
      settings.sync_pwd = settings.defaults.sync_pwd

      assert.equal(original_cwd, vim.loop.cwd())
    end)
  end)

  describe('down', function()
    it('sets cwd to cursor directory', function()
      local original_cwd = vim.loop.cwd()

      settings.sync_pwd = true
      util.cursor(2, 1)
      carbon.down()

      assert.equal(vim.loop.cwd(), string.format('%s/.github', original_cwd))

      carbon.reset()
      settings.sync_pwd = settings.defaults.sync_pwd
    end)

    it('releases registered listeners not in new cwd', function()
      local original_listeners = watcher.registered()

      util.cursor(2, 1)
      carbon.down()

      assert.not_same(original_listeners, watcher.registered())

      carbon.reset()
    end)
  end)

  describe('cd', function()
    it('sets cwd to target path', function()
      local jump_cwd = string.format('%s/test/specs', vim.loop.cwd())

      settings.sync_pwd = true
      util.cursor(2, 1)
      carbon.cd(jump_cwd)

      assert.equal(jump_cwd, vim.loop.cwd())

      carbon.reset()
      settings.sync_pwd = settings.defaults.sync_pwd
    end)
  end)

  describe('quit', function()
    it('closes the buffer', function()
      vim.cmd.edit('README.md')
      carbon.explore()
      helpers.type_keys(settings.actions.quit)

      assert.not_equal('carbon', vim.fn.bufname())
    end)
  end)

  describe('create', function()
    it('can create file', function()
      helpers.type_keys(
        string.format('%shello.txt<cr>', settings.actions.create)
      )

      assert.not_nil(
        vim.loop.fs_stat(string.format('%s/hello.txt', vim.loop.cwd()))
      )
    end)

    it('can create directory', function()
      helpers.type_keys(string.format('%shello/<cr>', settings.actions.create))

      assert.is_equal(
        1,
        vim.fn.isdirectory(string.format('%s/hello', vim.loop.cwd()))
      )
    end)

    it('can create deeply nested path', function()
      helpers.type_keys(
        string.format('%shello/world/test.txt<cr>', settings.actions.create)
      )

      assert.not_nil(
        vim.loop.fs_stat(
          string.format('%s/hello/world/test.txt', vim.loop.cwd())
        )
      )
    end)
  end)

  describe('delete', function()
    it('can delete file', function()
      helpers.ensure_path('.a/.a.txt')
      util.cursor(2, 1)
      helpers.type_keys(string.format('%sD', settings.actions.delete))

      assert.not_nil(vim.loop.fs_stat(string.format('%s/.a', vim.loop.cwd())))
      assert.is_nil(
        vim.loop.fs_stat(string.format('%s/.a/.a.txt', vim.loop.cwd()))
      )
    end)

    it('can delete directory', function()
      helpers.ensure_path('.a/')
      util.cursor(2, 1)
      helpers.type_keys(string.format('%sD', settings.actions.delete))

      assert.is_nil(vim.loop.fs_stat(string.format('%s/.a', vim.loop.cwd())))
    end)

    it('can partially delete deeply nested path using count', function()
      helpers.ensure_path('.a/.a/a.txt')
      util.cursor(2, 1)
      helpers.type_keys(string.format('2%sD', settings.actions.delete))

      assert.is_nil(vim.loop.fs_stat(string.format('%s/.a/.a', vim.loop.cwd())))
      assert.not_nil(vim.loop.fs_stat(string.format('%s/.a', vim.loop.cwd())))
    end)

    it('can completely delete deeply nested path using count', function()
      helpers.ensure_path('.a/.a/.a.txt')
      util.cursor(2, 1)
      helpers.type_keys(string.format('1%sD', settings.actions.delete))

      assert.is_nil(vim.loop.fs_stat(string.format('%s/.a', vim.loop.cwd())))
    end)
  end)

  describe('move', function()
    it('can rename path', function()
      helpers.ensure_path('.a/.a.txt')
      util.cursor(2, 1)
      helpers.type_keys(string.format('%s1<cr>', settings.actions.move))
      helpers.wait_for_events()

      assert.is_nil(
        vim.loop.fs_stat(string.format('%s/.a/.a.txt', vim.loop.cwd()))
      )
      assert.not_nil(
        vim.loop.fs_stat(string.format('%s/.a/.a.txt1', vim.loop.cwd()))
      )

      helpers.delete_path('.a/')
    end)

    it('creates intermediate directories', function()
      helpers.ensure_path('.a/.a.txt')
      util.cursor(2, 1)
      helpers.type_keys(
        string.format('%s<bs><bs><bs><bs>/b/c<cr>', settings.actions.move)
      )

      assert.is_nil(
        vim.loop.fs_stat(string.format('%s/.a/.a.txt', vim.loop.cwd()))
      )
      assert.not_nil(
        vim.loop.fs_stat(string.format('%s/.a/.a/b/c', vim.loop.cwd()))
      )
    end)
  end)
end)
