if exists('g:loaded_operator_swap')
  finish
endif

let g:loaded_operator_swap = 1


nnoremap <silent> <Plug>(operator-swap-area1)      :<C-u>call  operator#swap#normal(1)<CR>
nnoremap <silent> <Plug>(operator-swap-area2-swap) :<C-u>call  operator#swap#normal(2)<CR>
nnoremap <silent> <Plug>(operator-swap-predot)     :<C-u>:call operator#swap#predot#set()<CR>

xnoremap <silent> <Plug>(operator-swap-area1)      <Esc>:call  operator#swap#visual(1)<CR>gvg@
xnoremap <silent> <Plug>(operator-swap-area2-swap) <Esc>:call  operator#swap#visual(2)<CR>gvg@
