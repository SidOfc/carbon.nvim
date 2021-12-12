let s:handlers = luaeval('require("carbon.handlers")')

function! carbon#handlers#cursor(...)
  return call(s:handlers.cursor, a:000)
endfunction

function! carbon#handlers#toggle(...)
  return call(s:handlers.toggle, a:000)
endfunction

function! carbon#handlers#hsplit(...)
  return call(s:handlers.hsplit, a:000)
endfunction

function! carbon#handlers#vsplit(...)
  return call(s:handlers.vsplit, a:000)
endfunction

function! carbon#handlers#move(...)
  return call(s:handlers.move, a:000)
endfunction

function! carbon#handlers#create(...)
  return call(s:handlers.create, a:000)
endfunction

function! carbon#handlers#destroy(...)
  return call(s:handlers.destroy, a:000)
endfunction
