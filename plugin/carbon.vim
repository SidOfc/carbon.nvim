if exists('g:loaded_carbon')
  finish
endif

let g:loaded_carbon = 1

noremap <unique> <Plug>(carbon-move)    :call carbon#handlers#move()<Cr>
noremap <unique> <Plug>(carbon-create)  :call carbon#handlers#create()<Cr>
noremap <unique> <Plug>(carbon-destroy) :call carbon#handlers#destroy()<Cr>
noremap <unique> <Plug>(carbon-cursor)  :call carbon#handlers#cursor()<Cr>
noremap <unique> <Plug>(carbon-hsplit)  :call carbon#handlers#hsplit()<Cr>
noremap <unique> <Plug>(carbon-vsplit)  :call carbon#handlers#vsplit()<Cr>

call carbon#initialize()
