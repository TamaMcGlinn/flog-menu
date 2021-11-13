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

### disclaimer!

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
- [twiggy](https://github.com/sodapopcan/vim-twiggy)
- [fzf-checkout](https://github.com/stsewd/fzf-checkout.vim)
- [quickui](https://github.com/skywind3000/vim-quickui)
- [flog-menu](https://github.com/TamaMcGlinn/vim-flogmenu)

I also recommend these other extensions to vim-flog:

- [flog-teamjump](https://github.com/TamaMcGlinn/flog-teamjump)
- [flog-forest](https://github.com/TamaMcGlinn/flog-forest)
- [flog-navigate](https://github.com/TamaMcGlinn/flog-navigate)

Of course, you are recommended to use a plugin manager, for instance:

Using [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'tpope/vim-fugitive'
Plug 'rbong/vim-flog'
Plug 'skywind3000/vim-quickui'
Plug 'sodapopcan/vim-twiggy'
Plug 'stsewd/fzf-checkout.vim'
Plug 'TamaMcGlinn/flog-menu'

" recommended other extensions (optional)
Plug 'TamaMcGlinn/flog-teamjump'
Plug 'TamaMcGlinn/flog-forest'
Plug 'TamaMcGlinn/flog-navigate'
```

If you need to modify some of these, check the repository out
somewhere, and add that directory as a plugin. For example:

```vim
Plug '~/code/vimplugins/vim-flogmenu'
```

When you modify such code, you will need to
`source %` to make the changes take effect.

##### sidenote:

You may notice that the git log looks quite different in the screenshot
from default vim-flog. When
[this issue](https://github.com/rbong/vim-flog/issues/49) is resolved,
instructions will appear below to optionally switch to this behaviour.

## Optional configuration

### Context menu bindings

Add this to your vimrc to bind `<leader>m` to open the contextmenu:

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

" Recommended: set the quickui border style
let g:quickui_border_style = 2
```

### Open git menu

If you just wanted the context menu on the git log, you don't 
need leader-mapper installed, and you're done installing now.

Bind something to open the menu. Example given is `<Space>`:

```vim
nnoremap <Space> <Nop>
let mapleader = "\<Space>"

nnoremap <silent> <leader> :LeaderMapper<CR>
```

Now pick one of the options below.

##### sidenote:

If you used something for LeaderMapper as above, that is a prefix
of any of your existing mappings, there will be surprises. For example, if
you have `<leader>l` bound to something, but `<leader>` alone opens a
leader-mapper menu in which `l` is an option, then the leader-mapper option
will be chosen when you press the keys slowly enough for the menu to pop up,
but the pre-existing mapping will be picked if you press them faster. 
To avoid this, you should either assign an unused `:LeaderMapper` mapping
as you do for any new command you map, or migrate all of your bindings into
leadermapper menu's.

#### Option 1: Add git menu into existing menu-tree

If you already use leader-mapper, you might want to fit the git menu into
your existing config like this:

```vim
" Define the menu content with a Vim dictionary
let g:leaderMenu = {'name':  'Main menu',
             \'g': [g:flogmenu_gitmenu,  'Git'],
             \'n': [myNavMenu,           'Navigate'],
             \'q': [':tabc',       'Example direct command to close tab'],
             \}
```

Note that the above has to go into `~/.vim/after/plugin/flogmenu_config.vim`
(for Vim), or `~/.config/nvim/after/plugin/flogmenu_config.vim` (for NeoVim).

#### Option 2: Open git menu directly

If you don't want to use leader-mapper for anything but the git menu, use:

```vim
let g:leaderMenu = g:flogmenu_gitmenu
```

Now whatever you mapped to :LeaderMapper will open the flogmenu defined git menu.

Note that the above has to go into `~/.vim/after/plugin/flogmenu_config.vim`
(for Vim), or `~/.config/nvim/after/plugin/flogmenu_config.vim` (for NeoVim).

#### Option 3: Copy git menu and customize

Even if you like the current flogmenu defined git menu, I might change it later
for no apparent reason, and you will hate me because now your muscle memory is
wrong. It's probably best to define the menu yourself. You can copy
the menu's defined in [plugin/flogmenu.vim](plugin/flogmenu.vim) into your vimrc
and then modify them:

```vim
let g:personal_logmenu = {'name': 'Flog Menu',
 \'l': [':Flog -all', 'Normal'],
 \}

let g:personal_gitmenu = {'name': 'Git Menu',
             \'s': [':Gstatus', 'Status'],
             \'l': [g:personal_logmenu, 'Log'],
             \}

let g:leaderMenu = g:personal_gitmenu
```

This option is probably best, since it can just go straight in your vimrc file,
and offers you a stable interface.

