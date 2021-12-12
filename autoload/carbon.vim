let s:carbon = luaeval('require("carbon")')

function! carbon#setup(...)
  return call(s:carbon.setup, a:000)
endfunction

function! carbon#initialize(...)
  return call(s:carbon.initialize, a:000)
endfunction
