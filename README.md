# vim-operator-swap

This vim plugin provides for the exchange of two selected regions.

## Usage

**Settings**

Here, it is assumed that the following mappings are set in vimrc.

```vim
" Normal mode
nmap sn <Plug>(operator-swap-area1)
nmap sm <Plug>(operator-swap-area2-swap)
" Dot mapping prevents the cursor from jumping to unexpected place.
" Please change `:normal! .<CR>` according to your setting.
nmap .  <Plug>(operator-swap-predot):normal! .<CR>

" Visual mode
xmap sn <Plug>(operator-swap-area1)
xmap sm <Plug>(operator-swap-area2-swap)
```

**Operator**

In normal mode, `sn` and `sm` are operators for vim, which are used with text objects to select an area.
For example, suppose you want to exchange the characters `vim` and `operator` in the string `vim-operator-swap`.
It can be swapped by the following steps.

1. Move the cursor to the character `vim`.
1. Type `sniw`. The character is highlighted in purple. This area is called area1.
1. Move the cursor to the character `operator`.
1. Type `smiw`. The `swap` character area (area2) is highlighted in green, while area1 and area2 are swapped.
1. If you type `3smiw` instead of `smiw`, the text of `vim` and `operator-swap` are exchanged.

`sn` simply selects a region, but `sm` performs a swap in addition to selecting a region.
However, if a region selected by `sn` and `sm` overlaps, the overlap region is highlighted in red and cannot be exchanged.
For example, if you select `vim` and `vim-operator`, the character `vim` is highlighted in red.

**Dot mapping**

If a text object used in area1 is the same as that used in area2 (for example, `sniw` and `smiw`), you can use a dot (`.`) instead of `sm` to reduce type.
The dot selects a text using a text object used in area1, and then performs a swap.
By mapping the dot as described above, the cursor is prevented from jumping in unexpected place.

**Visual mode**

Even in visual mode, `sn` selects `text1` and `sm` selects `text2` and swaps them.

**Combining normal mode with visual mode**

You can exchange text by combination of operator-text object and visual mode.
For example, when you select a `text1` in visual mode and select a `text2` using the operator and text object, you can swap `text1` and `text2`.

**Highlight Settings**

Highlight color and time can be changed with the following command.

```vim
" The default highlight time is 300 ms for area1 and 600 ms for area2.
" Selecting zero turns off highlighting.
let g:operator_swap_area1_highlight_time = 300
let g:operator_swap_area2_highlight_time = 600

" The followings set the highlight color for area1, area2, and overlap area.
hi OperatorSwapArea1       cterm=bold ctermfg=81 ctermbg=92 guifg=#5fd7ff guibg=#8700d7
hi OperatorSwapArea2       cterm=bold ctermfg=81 ctermbg=2  guifg=#5fd7ff guibg=#008000
hi OperatorSwapOverlapArea cterm=bold ctermfg=81 ctermbg=9  guifg=#5fd7ff guibg=#ff6060
```

## Installation

Please add this repository in your plugin manager.
For example, if you are using [dein](https://github.com/Shougo/dein.vim):

```vim
call dein#add('SausageCats/vim-operator-swap')
```
