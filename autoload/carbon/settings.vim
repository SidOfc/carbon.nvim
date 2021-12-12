let s:settings = luaeval('require("carbon.settings")')

function! carbon#settings#extend(...)
  return call(s:settings.extend, a:000)
endfunction


