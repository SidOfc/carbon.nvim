local util = require('carbon.util')

describe('carbon.util', function()
  it('plug(name) returns <plug>(carbon-{name})', function()
    assert.equals('<plug>(carbon-test)', util.plug('test'))
  end)
end)
