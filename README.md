# Vim Flog Menu

## Installation

You need to install [fugitive](https://github.com/tpope/vim-fugitive),
[flog](https://github.com/rbong/vim-flog),
[quickui](https://github.com/skywind3000/vim-quickui) and
[flogmenu](https://github.com/TamaMcGlinn/vim-flogmenu) together.

Of course, you are recommended to use a plugin manager, for instance:

Using [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'tpope/vim-fugitive'
Plug 'rbong/vim-flog'
Plug 'skywind3000/vim-quickui'
Plug 'TamaMcGlinn/vim-flogmenu'
```

Using [dein](https://github.com/Shougo/dein.vim):

```vim
call dein#add('tpope/vim-fugitive')
call dein#add('rbong/vim-flog')
call dein#add('skywind3000/vim-quickui')
call dein#add('TamaMcGlinn/vim-flogmenu')
```

Using [vundle](https://github.com/gmarik/Vundle.vim):

```vim
Plugin 'tpope/vim-fugitive'
Plugin 'rbong/vim-flog'
Plugin 'skywind3000/vim-quickui'
Plugin 'TamaMcGlinn/vim-flogmenu'
```

## Create bindings

Add bindings to the menu entrypoints to your vimrc. For example:

```viml
" Flog menu bindings
augroup flogmenu
  autocmd FileType floggraph nno <buffer> <Leader>n :<C-U>call flogmenu#open_main_menu()<CR>
augroup END
```

