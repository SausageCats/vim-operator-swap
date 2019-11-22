set runtimepath^=$PWD


let g:operator_swap_area1_highlight_time = 300
let g:operator_swap_area2_highlight_time = 600


hi OperatorSwapArea1       cterm=bold ctermfg=81 ctermbg=92 guifg=#5fd7ff guibg=#8700d7
hi OperatorSwapArea2       cterm=bold ctermfg=81 ctermbg=2  guifg=#5fd7ff guibg=#008000
hi OperatorSwapOverlapArea cterm=bold ctermfg=81 ctermbg=9  guifg=#5fd7ff guibg=#ff6060


vmap sn <Plug>(operator-swap-area1)
vmap sm <Plug>(operator-swap-area2-swap)

nmap sn <Plug>(operator-swap-area1)
nmap sm <Plug>(operator-swap-area2-swap)
nmap .  <Plug>(operator-swap-predot):normal! .<CR>
