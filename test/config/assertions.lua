local say = require('say')
local assert = require('luassert.assert')
local entry = require('carbon.entry')

local function is_entry(_, arguments)
  local target = arguments[1]

  if type(target) ~= 'table' then
    return false
  end

  return entry == getmetatable(target)
end

say:set(
  'assertion.is_entry.positive',
  'Expected %s to be instance of carbon.entry.new'
)

say:set(
  'assertion.is_entry.negative',
  'Expected %s to not be instance of carbon.entry.new'
)

assert:register(
  'assertion',
  'is_entry',
  is_entry,
  'assertion.is_entry.positive',
  'assertion.is_entry.negative'
)
