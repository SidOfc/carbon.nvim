local util = require('carbon.util')
local settings = require('carbon.settings')
local helpers = require('test.config.helpers')

describe('carbon', function()
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
end)
