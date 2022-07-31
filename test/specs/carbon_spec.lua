local carbon = require('carbon')
local test_util = require('test.config.util')

carbon.initialize()

describe('carbon', function()
  it('opens a buffer with name "carbon"', function()
    assert.equals('carbon', vim.fn.bufname())
  end)

  it('opens a buffer with filetype "carbon"', function()
    assert.equals('carbon', vim.o.filetype)
  end)

  it('displays the contents of the current directory', function()
    assert.equals(
      table.concat({
        string.format('%s/', test_util.cwd_dirname()),
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
      }, '\n'),
      test_util.buf_tostring()
    )
  end)
end)
