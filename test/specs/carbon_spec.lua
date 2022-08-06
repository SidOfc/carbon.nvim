local util = require('carbon.util')
local settings = require('carbon.settings')
local helpers = require('test.config.helpers')

describe('carbon', function()
  describe('initialization', function()
    it('buffer has name "carbon"', function()
      assert.equal('carbon', vim.fn.bufname())
    end)

    it('buffer has filetype "carbon"', function()
      assert.equal('carbon', vim.o.filetype)
      assert.equal('carbon', vim.bo.filetype)
    end)

    it('shows contents of current directory', function()
      assert.same({
        vim.fn.fnamemodify(vim.loop.cwd(), ':t') .. '/',
        '  dev/init.lua',
        '+ doc/',
        '+ lua/',
        '  plugin/carbon.vim',
        '+ test/',
        '  .luacheckrc',
        '  LICENSE.md',
        '  Makefile',
        '  README.md',
        '  stylua.toml',
      }, vim.api.nvim_buf_get_lines(0, 0, -1, true))
    end)
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

      it(string.format('maps %s to carbon.%s()', plug, action), function()
        assert.is_number(
          string.find(string.lower(vim.fn.maparg(plug, 'n')), '<lua %w+')
        )
      end)
    end

    for action, key in pairs(settings.actions) do
      local plug = util.plug(action)

      it(string.format('maps %s to %s', key, plug), function()
        assert.same(string.lower(vim.fn.maparg(key, 'n')), plug)
      end)
    end
  end)
end)
