# Installation

You need to install [fugitive](https://github.com/tpope/vim-fugitive),
[flog](https://github.com/rbong/vim-flog),
[quickui](https://github.com/skywind3000/vim-quickui) and
[flogmenu](https://github.com/TamaMcGlinn/vim-flogmenu) together.

Of course, you are recommended to use a plugin manager, for instance:

## Using vim-plug

```
Plug 'tpope/vim-fugitive'
Plug 'rbong/vim-flog'
Plug 'skywind3000/vim-quickui'
Plug 'TamaMcGlinn/vim-flogmenu'
```

## Using dein

```
call dein#install('tpope/vim-fugitive')
call dein#install('rbong/vim-flog')
call dein#install('tpope/vim-fugitive')
call dein#install('tpope/vim-fugitive')
Plug 'rbong/vim-flog'
Plug 'skywind3000/vim-quickui'
Plug 'TamaMcGlinn/vim-flogmenu'
```


Add a binding to open the context menu to your vimrc:

```
augroup flog_menu
  autocmd FileType floggraph nno <buffer> <Leader>n :<C-U>call flogmenu#open_main_menu()<CR>
augroup END
```

