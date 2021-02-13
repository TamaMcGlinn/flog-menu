let g:flog_menu_commit_parse_error = 'flog_menu: unable to parse commit'

" set cursor to the last position
let g:flog_menu_opts = {'index':g:quickui#context#cursor}

fu! flog_menu#get_refs(commit)
  if type(a:commit) != v:t_dict
    throw g:flog_menu_commit_parse_error
  endif

  " TODO replace rest with this after freturncodelog PR#48 is approved
  " return flog#parse_ref_name_list(l:commit)
  let l:local_branches = []
  let l:remote_branches = []
  let l:special = []
  let l:tags = []

  if !empty(a:commit.ref_name_list)
    let l:refs = a:commit.ref_name_list

    let l:original_refs = split(a:commit.ref_names_unwrapped, ' \ze-> \|, \|\zetag: ')

    let l:i = 0
    while l:i < len(l:refs)
      let l:ref = l:refs[l:i]

      if l:ref =~# 'HEAD$\|^refs/'
        call add(l:special, l:ref)
      elseif l:original_refs[l:i] =~# '^tag: '
        call add(l:tags, l:ref)
      elseif flog#is_remote_ref(l:ref)
        call add(l:remote_branches, l:ref)
      else
        call add(l:local_branches, l:ref)
      endif

      let l:i += 1
    endwhile
  endif
  return [l:local_branches, l:remote_branches, l:tags, l:special]
endfunction

" fu! flog_menu#
fu! flog_menu#create_branch_menu() abort
  let l:commit = flog#get_commit_at_line()
  let [l:local_branches, l:remote_branches, l:tags, l:special] = flog_menu#get_refs(l:commit)
  let l:branch_menu = []
  for l:remote_branch in l:remote_branches
    call add(branch_menu, [l:local_branch, 'echo "' . l:local_branch . '"'])
  endfor
  call quickui#context#open(l:branch_menu, g:opts)
endfunction

fu! flog_menu#git(command) abort
  let l:cmd = substitute(fugitive#Prepare(a:command), "\'", '', 'g')
  let l:out = system(l:cmd)
  return substitute(out, '\c\C\n$', '', '')
endfunction

fu! flog_menu#remove_current_branch(local_branches) abort
  let l:current_branch = flog_menu#git('rev-parse --abbrev-ref HEAD')
  return filter(a:local_branches, 'l:current_branch != v:val')
endfunction

fu! flog_menu#checkout_menu() abort
  let l:commit = flog#get_commit_at_line()
  let [l:local_branches, l:remote_branches, l:tags, l:special] = flog_menu#get_refs(l:commit)
  let l:other_branches = flog_menu#remove_current_branch(l:local_branches)

  let l:current_commit = flog_menu#git('rev-parse HEAD')
  let l:full_commit_hash = fugitive#RevParse(l:commit.short_commit_hash)
  " Are we moving to a different commit? If so, check the git status is clean
  if l:current_commit != l:full_commit_hash
    call flog_menu#git('update-index --refresh')
    call flog_menu#git('diff-index --quiet HEAD --')
    let l:has_unstaged_changes = v:shell_error != 0
    if l:has_unstaged_changes
      call inputsave()
      let l:unstaged_info = flog_menu#git('diff --stat')
      let l:choice = input("Unstaged changes: \n" . l:unstaged_info . "\n> (a)bort / (d)iscard / (s)tash ")
      call inputrestore()
      if l:choice == 'd'
        call system('git checkout -- .')
      elseif l:choice == 's'
        call flog_menu#git('stash')
      else " All invalid input also means abort
        return
      endif
    endif
  endif

  " If there are other branches, these are the most likely choices to checkout
  let l:branch_menu = []
  if !empty(l:other_branches)
    if len(l:other_branches) > 1
      for l:local_branch in l:local_branches
        call add(branch_menu, [l:local_branch, 'echo "' . l:local_branch . '"'])
      endfor
      call add(branch_menu, ['-create branch', 'call flog_menu#create_branch_menu()'])
      call add(branch_menu, ['-detached HEAD', 'echo "TODO detach"'])
      call quickui#context#open(l:branch_menu, g:opts)
    else
      call flog_menu#git('checkout ' . l:local_branches[0])
      call flog#populate_graph_buffer()
      return
    endif
  endif
  " In addition, offer the choices to create branches for remote branches
  if !empty(l:remote_branches)
    for l:remote_branch in l:remote_branches
      echo l:remote_branch
    endfor
  endif
endfunction

let g:flog_menu_main_menu = [
                          \ ["&Checkout \t\\co", 'call flog_menu#checkout_menu()'],
                          \ ]

fu! flogmenu#open_main_menu() abort
  call quickui#context#open(g:flog_menu_main_menu, g:opts)
endfunction

