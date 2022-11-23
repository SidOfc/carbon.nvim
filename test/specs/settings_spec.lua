require('test.config.assertions')

local util = require('carbon.util')
local settings = require('carbon.settings')

describe('carbon.settings', function()
  describe('sync_pwd', function()
    it('is a boolean', function()
      assert.is_boolean(settings.sync_pwd)
    end)
  end)

  describe('compress', function()
    it('is a boolean', function()
      assert.is_boolean(settings.compress)
    end)
  end)

  describe('auto_open', function()
    it('is a boolean', function()
      assert.is_boolean(settings.auto_open)
    end)
  end)

  describe('keep_netrw', function()
    it('is a boolean', function()
      assert.is_boolean(settings.keep_netrw)
    end)

    it('sets vim.g.loaded_netrw', function()
      assert.is_same(1, vim.g.loaded_netrw)
    end)

    it('sets vim.g.loaded_netrwPlugin', function()
      assert.is_same(1, vim.g.loaded_netrwPlugin)
    end)

    it('deletes augroup FileExplorer', function()
      assert.is_nil(
        util.tbl_find(vim.api.nvim_get_autocmds({}), function(autocmd)
          return autocmd.group_name == 'FileExplorer'
        end)
      )
    end)

    it('deletes augroup Network', function()
      assert.is_nil(
        util.tbl_find(vim.api.nvim_get_autocmds({}), function(autocmd)
          return autocmd.group_name == 'Network'
        end)
      )
    end)
  end)

  describe('sync_on_cd', function()
    it('is a boolean', function()
      assert.is_boolean(settings.sync_on_cd)
    end)

    it('is a opposite of vim.o.autochdir', function()
      assert.not_same(settings.sync_on_cd, vim.o.autochdir)
    end)
  end)

  describe('sync_delay', function()
    it('is a number', function()
      assert.is_number(settings.sync_delay)
    end)
  end)

  describe('sidebar_width', function()
    it('is a number', function()
      assert.is_number(settings.sidebar_width)
    end)
  end)

  describe('always_reveal', function()
    it('is a boolean', function()
      assert.is_boolean(settings.always_reveal)
    end)
  end)

  describe('exclude', function()
    it('is a table of strings', function()
      assert.is_table(settings.exclude)

      for _, item in ipairs(settings.exclude) do
        assert.is_string(item)
      end
    end)
  end)

  describe('indicators', function()
    it('is a table', function()
      assert.is_table(settings.indicators)
    end)

    describe('indicators.expand', function()
      it('is a within ascii range', function()
        assert.is_true(string.byte(settings.indicators.expand) < 128)
      end)
    end)

    describe('indicators.collapse', function()
      it('is a within ascii range', function()
        assert.is_true(string.byte(settings.indicators.collapse) < 128)
      end)
    end)
  end)

  describe('flash', function()
    it('is a table', function()
      assert.is_table(settings.flash)
    end)

    describe('flash.delay', function()
      it('is a number', function()
        assert.is_number(settings.flash.delay)
      end)
    end)

    describe('flash.duration', function()
      it('is a number', function()
        assert.is_number(settings.flash.duration)
      end)
    end)
  end)

  describe('float_settings', function()
    it('is a function', function()
      assert.is_function(settings.float_settings)
    end)

    it('returns a table', function()
      assert.is_table(settings.float_settings())
    end)
  end)

  describe('actions', function()
    it('is a table', function()
      assert.is_table(settings.actions)
    end)

    for action, mapping in pairs(settings.actions) do
      describe(string.format('actions.%s', action), function()
        it('is not empty', function()
          assert.is_true(#mapping > 0)
        end)
      end)
    end
  end)

  describe('highlights', function()
    it('is a table', function()
      assert.is_table(settings.actions)
    end)

    for group, properties in pairs(settings.highlights) do
      describe(string.format('highlights.%s', group), function()
        it('is a table', function()
          assert.is_table(properties)
        end)
      end)
    end
  end)

  describe('defaults', function()
    it('is same as settings', function()
      assert.same(util.tbl_except(settings, { 'defaults' }), settings.defaults)
    end)

    it('does not change when settings change', function()
      settings.keep_netrw = not settings.keep_netrw

      assert.not_same(settings.keep_netrw, settings.defaults.keep_netrw)

      settings.keep_netrw = settings.defaults.keep_netrw
    end)
  end)
end)
