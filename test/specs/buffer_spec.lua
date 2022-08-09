local spy = require('luassert.spy')
local util = require('carbon.util')
local buffer = require('carbon.buffer')
local settings = require('carbon.settings')

describe('carbon.buffer', function()
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
    for action, key in pairs(settings.actions) do
      local plug = util.plug(action)

      it(string.format('binds %s to %s', key, plug), function()
        assert.same(string.lower(vim.fn.maparg(key, 'n')), plug)
      end)
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
end)
