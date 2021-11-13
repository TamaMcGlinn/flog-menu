# Vim Flog Menu

Flog-menu adds a context menu for the selected commit on the log graph,
similar to right-clicking in git GUI's:

![screenshot including the context-menu opened on the git graph](https://i.imgur.com/RlCGLk8.png)

and a
[leader-mapper](https://github.com/dpretet/vim-leader-mapper) menu you 
can activate to open git-related plugins with custom options.

![screenshot of git leader-mapper menu](https://i.imgur.com/V7Zse7g.png)

## The idea

You shouldn't have to remember the keybindings for git operations,
especially for those you seldom use.
Nor should you sacrifice screen space to controls as in mouse-based GUI's.

Like [tig](https://github.com/jonas/tig), [vim-flog](http://github.com/rbong/vim-flog/)
shows the git log graph fullscreen, and allows you to interact with that. 
However, where tig and flog "leave configuration to the user", flog-menu
aims to be pre-configured and comprehensive in showing all *sensible* options
(e.g. only showing `git push --force-with-lease`, not `git push --force`).

## Easy to learn, easy to master

Vim flog-menu should be so easy to use, that even a yucky non-vim-user could
use this as a replacement for commandline git. Flog-menu makes features from
git plugins such as vim-fugitive and vim-flog easy to find and unnecessary to
remember, by putting them in chained menus with textual descriptions just like
in fully fledged git editors like GitExtensions, SourceTree, SmartGit etc.
Each menu is navigable by j/k/arrows/mouse, and by pressing the bold letter.

## Optional configuration

Since the implementation is heavy on publicly accessible functions, you could easily
add your own direct bindings to the underlying operations and speed up your
workflow, without using the visual menus, if you prefer the traditional
'remember-your-keybindings' vim approach. Instead of using my context menu,
you could copy the 10 lines of config that define it, and change them around to
suit your config. However, if your change is useful for everyone, I'd prefer you
submit a merge request.

### Disclaimer

This plugin is work in progress. I have been using it for all git operations since the summer of 2021,
so I expect to have ironed out the bugs in my own most heavily used paths, but it is not fully tested.
Use at your own risk.

## Roadmap

Main menu:

- ✔️  push / pull
- ❌ configuring remotes
- ✔️  branch menu
- ✔️  search branches / tags

Context menu:

- ✔️  checkout
- ✔️  create branches
- ✔️  revert
- ✔️  rebase
- ✔️  reset mixed / hard
- ❌ use soft instead of mixed in bare repo's
- ✔️  fixup/amend a commit
- ❌ create (partial) bundles for sneakernet transfer

## Installation

You need to install:

- [fugitive](https://github.com/tpope/vim-fugitive)
- [flog](https://github.com/rbong/vim-flog)
- [quickui](https://github.com/skywind3000/vim-quickui)
- [flog-menu](https://github.com/TamaMcGlinn/vim-flogmenu)

I also recommend these other extensions to vim-flog:

- [flog-teamjump](https://github.com/TamaMcGlinn/flog-teamjump)
- [flog-forest](https://github.com/TamaMcGlinn/flog-forest)
- [flog-navigate](https://github.com/TamaMcGlinn/flog-navigate)

If installed, flog-menu integrates with these to provide additional functionality:

- [vim-signify](https://github.com/mhinz/vim-signify)
- [twiggy](https://github.com/sodapopcan/vim-twiggy)
- [fzf-checkout](https://github.com/stsewd/fzf-checkout.vim)

Of course, you are recommended to use a plugin manager, for instance:

Using [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'tpope/vim-fugitive'
Plug 'rbong/vim-flog'
Plug 'skywind3000/vim-quickui'
Plug 'TamaMcGlinn/flog-menu'

" recommended other extensions (optional)
Plug 'TamaMcGlinn/flog-teamjump'
Plug 'TamaMcGlinn/flog-forest'
Plug 'TamaMcGlinn/flog-navigate'

" additional (optional) functionality
Plug 'mhinz/vim-signify'
Plug 'sodapopcan/vim-twiggy'
Plug 'stsewd/fzf-checkout.vim'
```

## Optional configuration

### Bind to open function

Bind whatever you find comfortable to opening flogmenu (in a new tab):

```vim
" open the full UI
nnoremap <leader>ga :call flogmenu#open_all_windows()<CR>
" open just the git log
nnoremap <silent> <leader>gll :call flogmenu#open_git_log()<CR>
```

### Context menu bindings

Once in the flog git log graph, you will want to open the contextmenu.
For instance, to use `<space>m` for that, use:

```vim
" Set the leader to <space>
" Custom mappings in normal mode that start with space
" will not conflict with default vim commands
let mapleader = " "

" Flog menu bindings
augroup flogmenu
  autocmd FileType floggraph nno <buffer> <Leader>m :<C-U>call flogmenu#open_main_contextmenu()<CR>
  autocmd FileType floggraph vno <buffer> <Leader>m :<C-U>call flogmenu#open_visual_contextmenu()<CR>
augroup END
```

(TODO replace above with plug binding, which is apparently easier on users)

### Set border style

Highly recommended. The default is messy.

```vim
" Recommended: set the quickui border style
let g:quickui_border_style = 2
```

### Signify compare bindings

If you are using [vim-signify](https://github.com/mhinz/vim-signify) as well,
flogmenu can integrate with that
to allow you compare to a given commit using signify.

Open the commit log, browse to a commit and select `[C]ompare` from the contextmenu.
The signify column will update to reflect changes compared to that commit.
Use `:SignifyReset` to go back to the default signify behaviour, comparing to the
last committed version (HEAD).

Here is an example config, where the g square bracket bindings allow me to cycle
deeper/shallower comparisons to HEAD, `gS` resets and `gp` is for "compare to parent".

```vim
nnoremap <leader>gS :SignifyReset<CR>
nnoremap <leader>g[ :CompareOlder<CR>
nnoremap <leader>g] :CompareNewer<CR>
nnoremap <leader>gp :SignifyReset<CR>:SignifyOlder<CR>
```

### Additional direct bindings

Some git features have no bearing
on the git graph (or flogmenu, in fact).
The context menu does not include anything for these
but I recommend global bindings. For example:

```vim
" (force)push/fetch/pull
nnoremap <leader>gj :Git fetch --all<CR>
nnoremap <leader>gJ :call Track_and_pull()<CR>
nnoremap <leader>gk :Git push<CR>
nnoremap <leader>gK :Git push --force-with-lease<CR>

" Stage this file
nnoremap <leader>gg :Git add %<CR>

" Same as `cc` from fugitive buffer
nnoremap <leader>gc :Git commit<CR>

" Reset this file to 
nnoremap <leader>gR :Gread<CR>

" When viewing some git version of file, switch to working copy of same file
nnoremap <leader>ge :Gedit<CR>

" Blame file
nnoremap <leader>gz :Git blame<CR>
```
