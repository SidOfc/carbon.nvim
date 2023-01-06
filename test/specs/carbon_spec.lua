require('test.config.assertions')

local spy = require('luassert.spy')
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
    vim.cmd.only()
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

  describe('close_parent', function()
    it('closes parent of cursor entry and moves cursor', function()
      util.cursor(7, 1)
      carbon.edit()
      util.cursor(9, 1)
      carbon.close_parent()

      assert.equal(7, vim.fn.line('.'))
      assert.equal(3, vim.fn.col('.'))
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

  describe('explore_sidebar', function()
    it(
      'shows the buffer to the left of the current buffer by default',
      function()
        util.cursor(12, 1)
        carbon.edit()

        local before_bufname = vim.fn.bufname()

        carbon.explore_sidebar()
        vim.cmd.wincmd('l')

        assert.equal(before_bufname, vim.fn.bufname())

        vim.cmd.bdelete()
      end
    )
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
    it('calls buffer.create', function()
      local buffer_create = spy.on(buffer, 'create')

      carbon.create()
      helpers.type_keys('<esc>')

      assert.spy(buffer_create).is_called()
    end)
  end)

  describe('delete', function()
    it('calls buffer.delete', function()
      local buffer_delete = spy.on(buffer, 'delete')

      carbon.delete()
      helpers.type_keys('<esc>')

      assert.spy(buffer_delete).is_called()
    end)
  end)

  describe('move', function()
    it('calls buffer.move', function()
      local buffer_move = spy.on(buffer, 'move')

      carbon.move()
      helpers.type_keys('<esc>')

      assert.spy(buffer_move).is_called()
    end)
  end)
end)
