# Vim Flog Menu

Flogmenu adds a context menu for the selected commit on the log graph,
similar to right-clicking in git GUI's, and a main menu shown atop the window
when activated.

This plugin is an early work in progress.
[✅] Help welcome
[❌] Not production-ready

You shouldn't have to remember the keybindings for git operations,
especially for those you seldom use.
Nor should you sacrifice screen space to controls as in mouse-based GUI's.

Like [tig](https://github.com/jonas/tig), flogmenu shows the git log graph
fullscreen, and allows you to interact with that. However, where tig and flog
"leave configuration to the user", flogmenu
aims to be pre-configured and comprehensive in showing all sensible options.

## Easy to learn, easy to master

Vim flogmenu should be so easy to use, that even a yucky non-vim-user could
use this as a replacement for commandline git. Flogmenu makes features from
git plugins such as vim-fugitive and vim-flog easy to find and unnecessary to
remember, by putting them in chained menus with textual descriptions just like
in fully fledged git editors like GitExtensions, SourceTree, SmartGit etc.

Each menu is navigable by mouse, and by pressing the bold letter. Since the
implementation is heavy on publicly accessible functions, you could easily
add your own direct bindings to the underlying operations and speed up your
workflow.

## Roadmap

[❌] Main menu:
[❌] configuring remotes

[✅] Context menu:
[✅] checkout
[✅] create branches
[❌] rebase

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

Add this to your vimrc to bind `<space>n` to open the contextmenu and
`<space>m` to open the main menu.

```viml
" Set the leader to <space>
" Custom mappings in normal mode that start with space
" will not conflict with default vim commands
let mapleader = " "

" Flog menu bindings
augroup flogmenu
  autocmd FileType floggraph nno <buffer> <Leader>n :<C-U>call flogmenu#open_main_contextmenu()<CR>
augroup END

" Recommended: set the quickui border style
let g:quickui_border_style = 2
```

