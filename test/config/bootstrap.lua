require('plenary').test_harness.test_directory(
  string.format('%s/test/specs', vim.loop.cwd()),
  { minimal_init = 'test/config/init.lua' }
)

print('\n')
