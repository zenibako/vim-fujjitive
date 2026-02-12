" fujjitive.vim - A Jujutsu (jj) wrapper so awesome, it should be illegal
" Maintainer:   Tim Pope <http://tpo.pe/>
" Version:      3.7
" Based on fugitive.vim, adapted for Jujutsu VCS

if exists('g:loaded_fujjitive')
  finish
endif
let g:loaded_fujjitive = 1

let s:bad_jj_dir = '/$\|^fujjitive:'

" FujjitiveJJDir() returns the detected JJ dir for the given buffer number,
" or the current buffer if no argument is passed.  This will be an empty
" string if no JJ dir was found.  Use !empty(FujjitiveJJDir()) to check if
" Fujjitive is active in the current buffer.  Do not rely on this for direct
" filesystem access; use FujjitiveFind('.jj/whatever') instead.
function! FujjitiveJJDir(...) abort
  if v:version < 704
    return ''
  elseif !a:0 || type(a:1) == type(0) && a:1 < 0 || a:1 is# get(v:, 'true', -1)
    if exists('g:fujjitive_event')
      return g:fujjitive_event
    endif
    let dir = get(b:, 'jj_dir', '')
    if empty(dir) && (empty(bufname('')) && &filetype !=# 'netrw' || &buftype =~# '^\%(nofile\|acwrite\|quickfix\|terminal\|prompt\)$')
      return FujjitiveExtractJJDir(getcwd())
    elseif (!exists('b:jj_dir') || b:jj_dir =~# s:bad_jj_dir) && &buftype =~# '^\%(nowrite\)\=$'
      let b:jj_dir = FujjitiveExtractJJDir(bufnr(''))
      return b:jj_dir
    endif
    return dir =~# s:bad_jj_dir ? '' : dir
  elseif type(a:1) == type(0) && a:1 isnot# 0
    if a:1 == bufnr('') && (!exists('b:jj_dir') || b:jj_dir =~# s:bad_jj_dir) && &buftype =~# '^\%(nowrite\)\=$'
      let b:jj_dir = FujjitiveExtractJJDir(a:1)
    endif
    let dir = getbufvar(a:1, 'jj_dir')
    return dir =~# s:bad_jj_dir ? '' : dir
  elseif type(a:1) == type('')
    return substitute(s:Slash(a:1), '/$', '', '')
  elseif type(a:1) == type({})
    return get(a:1, 'fujjitive_dir', get(a:1, 'jj_dir', ''))
  else
    return ''
  endif
endfunction

" FujjitiveReal() takes a fujjitive:// URL and returns the corresponding path in
" the work tree.  This may be useful to get a cleaner path for inclusion in
" the statusline, for example.  Note that the file and its parent directories
" are not guaranteed to exist.
"
" This is intended as an abstract API to be used on any "virtual" path.  For a
" buffer named foo://bar, check for a function named FooReal(), and if it
" exists, call FooReal("foo://bar").
function! FujjitiveReal(...) abort
  let file = a:0 ? a:1 : @%
  if type(file) ==# type({})
    let dir = FujjitiveJJDir(file)
    let tree = s:Tree(dir)
    return s:VimSlash(empty(tree) ? dir : tree)
  elseif file =~# '^\a\a\+:' || a:0 > 1
    return call('fujjitive#Real', [file] + a:000[1:-1])
  elseif file =~# '^/\|^\a:\|^$'
    return file
  else
    return fnamemodify(file, ':p' . (file =~# '[\/]$' ? '' : ':s?[\/]$??'))
  endif
endfunction

" FujjitiveFind() takes a Fujjitive object and returns the appropriate Vim
" buffer name.  You can use this to generate Fujjitive URLs ("HEAD:README") or
" to get the absolute path to a file in the JJ dir (".jj/HEAD"), the common
" dir (".jj/config"), or the work tree (":(top)Makefile").
"
" An optional second argument provides the JJ dir, or the buffer number of a
" buffer with a JJ dir.  The default is the current buffer.
function! FujjitiveFind(...) abort
  if a:0 && (type(a:1) ==# type({}) || type(a:1) ==# type(0))
    return call('fujjitive#Find', a:000[1:-1] + [FujjitiveJJDir(a:1)])
  else
    return fujjitive#Find(a:0 ? a:1 : bufnr(''), FujjitiveJJDir(a:0 > 1 ? a:2 : -1))
  endif
endfunction

" FujjitiveParse() takes a fujjitive:// URL and returns a 2 element list
" containing an object name ("commit:file") and the JJ dir.  It's effectively
" the inverse of FujjitiveFind().
function! FujjitiveParse(...) abort
  let path = s:Slash(a:0 ? a:1 : @%)
  if path !~# '^fujjitive://'
    return ['', '']
  endif
  let [rev, dir] = fujjitive#Parse(path)
  if !empty(dir)
    return [rev, dir]
  endif
  throw 'fujjitive: invalid Fugitive URL ' . path
endfunction

" FujjitiveJJVersion() queries the version of Git in use.  Pass up to 3
" arguments to return a Boolean of whether a certain minimum version is
" available (FujjitiveJJVersion(2,3,4) checks for 2.3.4 or higher) or no
" arguments to get a raw string.
function! FujjitiveJJVersion(...) abort
  return call('fujjitive#GitVersion', a:000)
endfunction

" FujjitiveResult() returns an object encapsulating the result of the most
" recent :JJ command.  Will be empty if no result is available.  During a
" User FujjitiveChanged event, this is guaranteed to correspond to the :Git
" command that triggered the event, or be empty if :JJ was not the trigger.
" Pass in the name of a temp buffer to get the result object for that command
" instead.  Contains the following keys:
"
" * "args": List of command arguments, starting with the subcommand.  Will be
"   empty for usages like :JJ --help.
" * "jj_dir": JJ dir of the relevant repository.
" * "exit_status": The integer exit code of the process.
" * "flags": Flags passed directly to JJ, like -c and --help.
" * "file": Path to file containing command output.  Not guaranteed to exist,
"   so verify with filereadable() before trying to access it.
function! FujjitiveResult(...) abort
  return call('fujjitive#Result', a:000)
endfunction

" FujjitiveExecute() runs JJ with a list of arguments and returns a dictionary
" with the following keys:
"
" * "exit_status": The integer exit code of the process.
" * "stdout": The stdout produced by the process, as a list of lines.
" * "stderr": The stdout produced by the process, as a list of lines.
"
" An optional second argument provides the JJ dir, or the buffer number of a
" buffer with a JJ dir.  The default is the current buffer.
"
" An optional final argument is a callback Funcref, for asynchronous
" execution.
function! FujjitiveExecute(args, ...) abort
  return call('fujjitive#Execute', [a:args] + a:000)
endfunction

" FujjitiveShellCommand() turns an array of arguments into a JJ command string
" which can be executed with functions like system() and commands like :!.
" Integer arguments will be treated as buffer numbers, and the appropriate
" relative path inserted in their place.
"
" An optional second argument provides the JJ dir, or the buffer number of a
" buffer with a JJ dir.  The default is the current buffer.
function! FujjitiveShellCommand(...) abort
  return call('fujjitive#ShellCommand', a:000)
endfunction

" FujjitiveConfig() get returns an opaque structure that can be passed to other
" FujjitiveConfig functions in lieu of a JJ directory.  This can be faster
" when performing multiple config queries.  Do not rely on the internal
" structure of the return value as it is not guaranteed.  If you want a full
" dictionary of every config value, use FujjitiveConfigGetRegexp('.*').
"
" An optional argument provides the JJ dir, or the buffer number of a
" buffer with a JJ dir.  The default is the current buffer.  Pass a blank
" string to limit to the global config.
function! FujjitiveConfig(...) abort
  return call('fujjitive#Config', a:000)
endfunction

" FujjitiveConfigGet() retrieves a JJ configuration value.  An optional second
" argument can be either the object returned by FujjitiveConfig(), or a Git
" dir or buffer number to be passed along to FujjitiveConfig().
function! FujjitiveConfigGet(name, ...) abort
  return get(call('FujjitiveConfigGetAll', [a:name] + (a:0 ? [a:1] : [])), -1, get(a:, 2, ''))
endfunction

" FujjitiveConfigGetAll() is like FujjitiveConfigGet() but returns a list of
" all values.
function! FujjitiveConfigGetAll(name, ...) abort
  return call('fujjitive#ConfigGetAll', [a:name] + a:000)
endfunction

" FujjitiveConfigGetRegexp() retrieves a dictionary of all configuration values
" with a key matching the given pattern.  Like git config --get-regexp, but
" using a Vim regexp.  Second argument has same semantics as
" FujjitiveConfigGet().
function! FujjitiveConfigGetRegexp(pattern, ...) abort
  return call('fujjitive#ConfigGetRegexp', [a:pattern] + a:000)
endfunction

" FujjitiveRemoteUrl() retrieves the remote URL for the given remote name,
" defaulting to the current branch's remote or "origin" if no argument is
" given.  Similar to `jj git remote get-url`, but also attempts to resolve HTTP
" redirects and SSH host aliases.
"
" An optional second argument provides the JJ dir, or the buffer number of a
" buffer with a JJ dir.  The default is the current buffer.
function! FujjitiveRemoteUrl(...) abort
  return call('fujjitive#RemoteUrl', a:000)
endfunction

" FujjitiveRemote() returns a data structure parsed from the remote URL.
" For example, for remote URL "https://me@example.com:1234/repo.git", the
" returned dictionary will contain the following:
"
" * "scheme": "https"
" * "authority": "user@example.com:1234"
" * "path": "/repo.git" (for SSH URLs this may be a relative path)
" * "pathname": "/repo.git" (always coerced to absolute path)
" * "host": "example.com:1234"
" * "hostname": "example.com"
" * "port": "1234"
" * "user": "me"
" * "path": "/repo.git"
" * "url": "https://me@example.com:1234/repo.git"
function! FujjitiveRemote(...) abort
  return call('fujjitive#Remote', a:000)
endfunction

" FujjitiveDidChange() triggers a FugitiveChanged event and reloads the summary
" buffer for the current or given buffer number's repository.  You can also
" give the result of a FujjitiveExecute() and that context will be made
" available inside the FugitiveChanged() event.
"
" Passing the special argument 0 (the number zero) softly expires summary
" buffers for all repositories.  This can be used after a call to system()
" with unclear implications.
function! FujjitiveDidChange(...) abort
  return call('fujjitive#DidChange', a:000)
endfunction

" FujjitiveHead() retrieves the name of the current branch. If the current HEAD
" is detached, FujjitiveHead() will return the empty string, unless the
" optional argument is given, in which case the hash of the current commit
" will be truncated to the given number of characters.
"
" An optional second argument provides the JJ dir, or the buffer number of a
" buffer with a JJ dir.  The default is the current buffer.
function! FujjitiveHead(...) abort
  if a:0 && (type(a:1) ==# type({}) || type(a:1) ==# type('') && a:1 !~# '^\d\+$')
    let dir = FujjitiveJJDir(a:1)
    let arg = get(a:, 2, 0)
  elseif a:0 > 1
    let dir = FujjitiveJJDir(a:2)
    let arg = a:1
  else
    let dir = FujjitiveJJDir()
    let arg = get(a:, 1, 0)
  endif
  if empty(dir)
    return ''
  endif
  return fujjitive#Head(arg, dir)
endfunction

function! FujjitivePath(...) abort
  if a:0 > 2 && type(a:1) ==# type({})
    return fujjitive#Path(a:2, a:3, FujjitiveJJDir(a:1))
  elseif a:0 && type(a:1) ==# type({})
    return FujjitiveReal(a:0 > 1 ? a:2 : @%)
  elseif a:0 > 1
    return fujjitive#Path(a:1, a:2, FujjitiveJJDir(a:0 > 2 ? a:3 : -1))
  else
    return FujjitiveReal(a:0 ? a:1 : @%)
  endif
endfunction

function! FujjitiveStatusline(...) abort
  if empty(FujjitiveJJDir(bufnr('')))
    return ''
  endif
  return fujjitive#Statusline()
endfunction

let s:resolved_jj_dirs = {}
function! FujjitiveActualDir(...) abort
  let dir = call('FujjitiveJJDir', a:000)
  if empty(dir)
    return ''
  endif
  if !has_key(s:resolved_jj_dirs, dir)
    let s:resolved_jj_dirs[dir] = s:ResolveJJDir(dir)
  endif
  return empty(s:resolved_jj_dirs[dir]) ? dir : s:resolved_jj_dirs[dir]
endfunction

let s:commondirs = {}
function! FujjitiveCommonDir(...) abort
  let dir = call('FujjitiveActualDir', a:000)
  if empty(dir)
    return ''
  endif
  if has_key(s:commondirs, dir)
    return s:commondirs[dir]
  endif
  if getfsize(dir . '/HEAD') >= 10
    let cdir = get(s:ReadFile(dir . '/commondir', 1), 0, '')
    if cdir =~# '^/\|^\a:/'
      let s:commondirs[dir] = s:Slash(FujjitiveVimPath(cdir))
    elseif len(cdir)
      let s:commondirs[dir] = simplify(dir . '/' . cdir)
    else
      let s:commondirs[dir] = dir
    endif
  else
    let s:commondirs[dir] = dir
  endif
  return s:commondirs[dir]
endfunction

function! FujjitiveWorkTree(...) abort
  let tree = s:Tree(FujjitiveJJDir(a:0 ? a:1 : -1))
  if tree isnot# 0 || a:0 > 1
    return tree
  else
    return ''
  endif
endfunction

function! FujjitiveIsJJDir(...) abort
  if !a:0 || type(a:1) !=# type('')
    return !empty(call('FujjitiveJJDir', a:000))
  endif
  let path = substitute(a:1, '[\/]$', '', '') . '/'
  return len(path) && getfsize(path.'HEAD') > 10 && (
        \ isdirectory(path.'objects') && isdirectory(path.'refs') ||
        \ getftype(path.'commondir') ==# 'file')
endfunction

function! s:ReadFile(path, line_count) abort
  if v:version < 800 && !filereadable(a:path)
    return []
  endif
  try
    return readfile(a:path, 'b', a:line_count)
  catch
    return []
  endtry
endfunction

let s:worktree_for_dir = {}
let s:dir_for_worktree = {}
function! s:Tree(path) abort
  if a:path =~# '/\.jj$'
    return len(a:path) ==# 4 ? '/' : a:path[0:-5]
  elseif a:path =~# '/\.git$'
    return len(a:path) ==# 5 ? '/' : a:path[0:-6]
  elseif a:path ==# ''
    return ''
  endif
  let dir = FujjitiveActualDir(a:path)
  if !has_key(s:worktree_for_dir, dir)
    let s:worktree_for_dir[dir] = ''
    let ext_wtc_pat = 'v:val =~# "^\\s*worktreeConfig *= *\\%(true\\|yes\\|on\\|1\\) *$"'
    let config = s:ReadFile(dir . '/config', 50)
    if len(config)
      let ext_wtc_config = filter(copy(config), ext_wtc_pat)
      if len(ext_wtc_config) == 1 && filereadable(dir . '/config.worktree')
         let config += s:ReadFile(dir . '/config.worktree', 50)
      endif
    else
      let worktree = fnamemodify(FujjitiveVimPath(get(s:ReadFile(dir . '/gitdir', 1), '0', '')), ':h')
      if worktree ==# '.'
        unlet! worktree
      endif
      if len(filter(s:ReadFile(FujjitiveCommonDir(dir) . '/config', 50), ext_wtc_pat))
        let config = s:ReadFile(dir . '/config.worktree', 50)
      endif
    endif
    if len(config)
      let wt_config = filter(copy(config), 'v:val =~# "^\\s*worktree *="')
      if len(wt_config)
        let worktree = FujjitiveVimPath(matchstr(wt_config[0], '= *\zs.*'))
      elseif !exists('worktree')
        call filter(config,'v:val =~# "^\\s*bare *= *true *$"')
        if empty(config)
          let s:worktree_for_dir[dir] = 0
        endif
      endif
    endif
    if exists('worktree')
      let s:worktree_for_dir[dir] = s:Slash(resolve(worktree))
      let s:dir_for_worktree[s:worktree_for_dir[dir]] = dir
    endif
  endif
  if s:worktree_for_dir[dir] =~# '^\.'
    return simplify(dir . '/' . s:worktree_for_dir[dir])
  else
    return s:worktree_for_dir[dir]
  endif
endfunction

function! s:CeilingDirectories() abort
  if !exists('s:ceiling_directories')
    let s:ceiling_directories = []
    let resolve = 1
    for dir in split($JJ_CEILING_DIRECTORIES, has('win32') ? ';' : ':', 1)
      if empty(dir)
        let resolve = 0
      elseif resolve
        call add(s:ceiling_directories, s:Slash(resolve(dir)))
      else
        call add(s:ceiling_directories, s:Slash(dir))
      endif
    endfor
  endif
  return s:ceiling_directories + get(g:, 'ceiling_directories', [s:Slash(fnamemodify(expand('~'), ':h'))])
endfunction

function! s:ResolveJJDir(git_dir) abort
  let type = getftype(a:git_dir)
  if type ==# 'dir' && FujjitiveIsJJDir(a:git_dir)
    return a:git_dir
  elseif type ==# 'link' && FujjitiveIsJJDir(a:git_dir)
    return resolve(a:git_dir)
  elseif type !=# ''
    let line = get(s:ReadFile(a:git_dir, 1), 0, '')
    let file_dir = s:Slash(FujjitiveVimPath(matchstr(line, '^gitdir: \zs.*')))
    if file_dir !~# '^/\|^\a:\|^$' && a:git_dir =~# '/\.git$' && FujjitiveIsJJDir(a:git_dir[0:-5] . file_dir)
      return simplify(a:git_dir[0:-5] . file_dir)
    elseif file_dir =~# '^/\|^\a:' && FujjitiveIsJJDir(file_dir)
      return file_dir
    endif
  endif
  return ''
endfunction

function! FujjitiveExtractJJDir(path) abort
  if type(a:path) ==# type({})
    return get(a:path, 'fujjitive_dir', get(a:path, 'jj_dir', ''))
  elseif type(a:path) == type(0)
    let path = s:Slash(a:path > 0 ? bufname(a:path) : bufname(''))
    if getbufvar(a:path, '&filetype') ==# 'netrw'
      let path = s:Slash(getbufvar(a:path, 'netrw_curdir', path))
    endif
  else
    let path = s:Slash(a:path)
  endif
  if path =~# '^fujjitive://'
    return fujjitive#Parse(path)[1]
  elseif empty(path)
    return ''
  endif
  let pre = substitute(matchstr(path, '^\a\a\+\ze:'), '^.', '\u&', '')
  if len(pre) && exists('*' . pre . 'Real')
    let path = {pre}Real(path)
  endif
  let root = s:Slash(fnamemodify(path, ':p:h'))
  let previous = ""
  let env_git_dir = len($JJ_DIR) ? s:Slash(simplify(fnamemodify(FujjitiveVimPath($JJ_DIR), ':p:s?[\/]$??'))) : ''
  call s:Tree(env_git_dir)
  let ceiling_directories = s:CeilingDirectories()
  while root !=# previous && root !~# '^$\|^//[^/]*$'
    if index(ceiling_directories, root) >= 0
      break
    endif
    if root ==# $JJ_WORK_TREE && FujjitiveIsJJDir(env_git_dir)
      return env_git_dir
    elseif has_key(s:dir_for_worktree, root)
      return s:dir_for_worktree[root]
    endif
    let jj_dir = substitute(root, '[\/]$', '', '') . '/.jj'
    if isdirectory(jj_dir)
      let s:resolved_jj_dirs[jj_dir] = jj_dir
      return jj_dir
    endif
    let dir = substitute(root, '[\/]$', '', '') . '/.git'
    let resolved = s:ResolveJJDir(dir)
    if !empty(resolved)
      let s:resolved_jj_dirs[dir] = resolved
      return dir is# resolved || s:Tree(resolved) is# 0 ? dir : resolved
    elseif FujjitiveIsJJDir(root)
      let s:resolved_jj_dirs[root] = root
      return root
    endif
    let previous = root
    let root = fnamemodify(root, ':h')
  endwhile
  return ''
endfunction

function! FujjitiveDetect(...) abort
  if v:version < 704
    return ''
  endif
  if exists('b:jj_dir') && b:jj_dir =~# '^$\|' . s:bad_jj_dir
    unlet b:jj_dir
  endif
  if !exists('b:jj_dir')
    let b:jj_dir = FujjitiveExtractJJDir(a:0 ? a:1 : bufnr(''))
  endif
  return ''
endfunction

function! FujjitiveJJPath(path) abort
  return s:Slash(a:path)
endfunction

if exists('+shellslash')

  function! s:Slash(path) abort
    return tr(a:path, '\', '/')
  endfunction

  function! s:VimSlash(path) abort
    return tr(a:path, '\/', &shellslash ? '//' : '\\')
  endfunction

  function FujjitiveVimPath(path) abort
    return tr(a:path, '\/', &shellslash ? '//' : '\\')
  endfunction

else

  function! s:Slash(path) abort
    return a:path
  endfunction

  function! s:VimSlash(path) abort
    return a:path
  endfunction

  if has('win32unix') && filereadable('/git-bash.exe')
    function! FujjitiveVimPath(path) abort
      return substitute(a:path, '^\(\a\):', '/\l\1', '')
    endfunction
  else
    function! FujjitiveVimPath(path) abort
      return a:path
    endfunction
  endif

endif

function! s:ProjectionistDetect() abort
  let file = s:Slash(get(g:, 'projectionist_file', ''))
  let dir = FujjitiveExtractJJDir(file)
  let base = matchstr(file, '^fujjitive://.\{-\}//\x\+')
  if empty(base)
    let base = s:Tree(dir)
  endif
  if !empty(base)
    if exists('+shellslash') && !&shellslash
      let base = tr(base, '/', '\')
    endif
    let file = FujjitiveFind('.jj/info/projections.json', dir)
    if filereadable(file)
      call projectionist#append(base, file)
    endif
  endif
endfunction

let s:addr_other = has('patch-8.1.560') || has('nvim-0.5.0') ? '-addr=other' : ''
let s:addr_tabs  = has('patch-7.4.542') ? '-addr=tabs' : ''
let s:addr_wins  = has('patch-7.4.542') ? '-addr=windows' : ''

if exists(':J') != 2
  command! -bang -nargs=? -range=-1 -complete=customlist,fujjitive#Complete J   exe fujjitive#Command(<line1>, <count>, +"<range>", <bang>0, "<mods>", <q-args>)
endif
command! -bang -nargs=? -range=-1 -complete=customlist,fujjitive#Complete JJ exe fujjitive#Command(<line1>, <count>, +"<range>", <bang>0, "<mods>", <q-args>)

if exists(':G') != 2
  command! -bang -nargs=? -range=-1 -complete=customlist,fujjitive#GitComplete G exe fujjitive#GitCommand(<line1>, <count>, +"<range>", <bang>0, "<mods>", <q-args>)
endif

if exists(':JJstatus') != 2 && get(g:, 'fujjitive_legacy_commands', 0)
  exe 'command! -bang -bar     -range=-1' s:addr_other 'Gstatus exe fujjitive#Command(<line1>, <count>, +"<range>", <bang>0, "<mods>", <q-args>)'
        \ '|echohl WarningMSG|echomsg ":JJstatus is deprecated in favor of :JJ (with no arguments)"|echohl NONE'
endif

for s:cmd in ['Commit', 'Revert', 'Merge', 'Rebase', 'Pull', 'Push', 'Fetch', 'Blame']
  if exists(':G' . tolower(s:cmd)) != 2 && get(g:, 'fujjitive_legacy_commands', 0)
    exe 'command! -bang -nargs=? -range=-1 -complete=customlist,fujjitive#' . s:cmd . 'Complete G' . tolower(s:cmd)
          \ 'echohl WarningMSG|echomsg ":G' . tolower(s:cmd) . ' is deprecated in favor of :JJ ' . tolower(s:cmd) . '"|echohl NONE|'
          \ 'exe fujjitive#Command(<line1>, <count>, +"<range>", <bang>0, "<mods>", "' . tolower(s:cmd) . ' " . <q-args>)'
  endif
endfor
unlet s:cmd

exe "command! -bar -bang -nargs=? -complete=customlist,fujjitive#CdComplete Gcd  exe fujjitive#Cd(<q-args>, 0)"
exe "command! -bar -bang -nargs=? -complete=customlist,fujjitive#CdComplete Glcd exe fujjitive#Cd(<q-args>, 1)"

exe 'command! -bang -nargs=? -range=-1' s:addr_wins '-complete=customlist,fujjitive#GrepComplete Ggrep  exe fujjitive#GrepCommand(<line1>, <count>, +"<range>", <bang>0, "<mods>", <q-args>)'
exe 'command! -bang -nargs=? -range=-1' s:addr_wins '-complete=customlist,fujjitive#GrepComplete Glgrep exe fujjitive#GrepCommand(0, <count> > 0 ? <count> : 0, +"<range>", <bang>0, "<mods>", <q-args>)'

exe 'command! -bang -nargs=? -range=-1 -complete=customlist,fujjitive#LogComplete Gclog :exe fujjitive#LogCommand(<line1>,<count>,+"<range>",<bang>0,"<mods>",<q-args>, "c")'
exe 'command! -bang -nargs=? -range=-1 -complete=customlist,fujjitive#LogComplete GcLog :exe fujjitive#LogCommand(<line1>,<count>,+"<range>",<bang>0,"<mods>",<q-args>, "c")'
exe 'command! -bang -nargs=? -range=-1 -complete=customlist,fujjitive#LogComplete Gllog :exe fujjitive#LogCommand(<line1>,<count>,+"<range>",<bang>0,"<mods>",<q-args>, "l")'
exe 'command! -bang -nargs=? -range=-1 -complete=customlist,fujjitive#LogComplete GlLog :exe fujjitive#LogCommand(<line1>,<count>,+"<range>",<bang>0,"<mods>",<q-args>, "l")'

exe 'command! -bar -bang -nargs=*                          -complete=customlist,fujjitive#EditComplete   Ge       exe fujjitive#Open("edit<bang>", 0, "<mods>", <q-args>)'
exe 'command! -bar -bang -nargs=*                          -complete=customlist,fujjitive#EditComplete   Gedit    exe fujjitive#Open("edit<bang>", 0, "<mods>", <q-args>)'
exe 'command! -bar -bang -nargs=*                          -complete=customlist,fujjitive#EditComplete   Gpedit   exe fujjitive#Open("pedit", <bang>0, "<mods>", <q-args>)'
exe 'command! -bar -bang -nargs=* -range=-1' s:addr_other '-complete=customlist,fujjitive#EditComplete   Gsplit   exe fujjitive#Open((<count> > 0 ? <count> : "").(<count> ? "split" : "edit"), <bang>0, "<mods>", <q-args>)'
exe 'command! -bar -bang -nargs=* -range=-1' s:addr_other '-complete=customlist,fujjitive#EditComplete   Gvsplit  exe fujjitive#Open((<count> > 0 ? <count> : "").(<count> ? "vsplit" : "edit!"), <bang>0, "<mods>", <q-args>)'
exe 'command! -bar -bang -nargs=* -range=-1' s:addr_tabs  '-complete=customlist,fujjitive#EditComplete   Gtabedit exe fujjitive#Open((<count> >= 0 ? <count> : "")."tabedit", <bang>0, "<mods>", <q-args>)'
exe 'command! -bar -bang -nargs=*                          -complete=customlist,fujjitive#EditComplete   Gdrop    exe fujjitive#DropCommand(<line1>, <count>, +"<range>", <bang>0, "<mods>", <q-args>)'

if exists(':Gr') != 2
  exe 'command! -bar -bang -nargs=* -range=-1                -complete=customlist,fujjitive#ReadComplete   Gr     exe fujjitive#ReadCommand(<line1>, <count>, +"<range>", <bang>0, "<mods>", <q-args>)'
endif
exe 'command! -bar -bang -nargs=* -range=-1                -complete=customlist,fujjitive#ReadComplete   Gread    exe fujjitive#ReadCommand(<line1>, <count>, +"<range>", <bang>0, "<mods>", <q-args>)'

exe 'command! -bar -bang -nargs=* -complete=customlist,fujjitive#EditComplete Gdiffsplit  exe fujjitive#Diffsplit(1, <bang>0, "<mods>", <q-args>)'
exe 'command! -bar -bang -nargs=* -complete=customlist,fujjitive#EditComplete Ghdiffsplit exe fujjitive#Diffsplit(0, <bang>0, "<mods>", <q-args>)'
exe 'command! -bar -bang -nargs=* -complete=customlist,fujjitive#EditComplete Gvdiffsplit exe fujjitive#Diffsplit(0, <bang>0, "vertical <mods>", <q-args>)'

exe 'command! -bar -bang -nargs=* -complete=customlist,fujjitive#EditComplete Gw     exe fujjitive#WriteCommand(<line1>, <count>, +"<range>", <bang>0, "<mods>", <q-args>)'
exe 'command! -bar -bang -nargs=* -complete=customlist,fujjitive#EditComplete Gwrite exe fujjitive#WriteCommand(<line1>, <count>, +"<range>", <bang>0, "<mods>", <q-args>)'
exe 'command! -bar -bang -nargs=* -complete=customlist,fujjitive#EditComplete Gwq    exe fujjitive#WqCommand(   <line1>, <count>, +"<range>", <bang>0, "<mods>", <q-args>)'

exe 'command! -bar -bang -nargs=0 GRemove exe fujjitive#RemoveCommand(<line1>, <count>, +"<range>", <bang>0, "<mods>", <q-args>)'
exe 'command! -bar -bang -nargs=0 GUnlink exe fujjitive#UnlinkCommand(<line1>, <count>, +"<range>", <bang>0, "<mods>", <q-args>)'
exe 'command! -bar -bang -nargs=0 GDelete exe fujjitive#DeleteCommand(<line1>, <count>, +"<range>", <bang>0, "<mods>", <q-args>)'
exe 'command! -bar -bang -nargs=1 -complete=customlist,fujjitive#CompleteObject GMove   exe fujjitive#MoveCommand(  <line1>, <count>, +"<range>", <bang>0, "<mods>", <q-args>)'
exe 'command! -bar -bang -nargs=1 -complete=customlist,fujjitive#RenameComplete GRename exe fujjitive#RenameCommand(<line1>, <count>, +"<range>", <bang>0, "<mods>", <q-args>)'
if exists(':Gremove') != 2 && get(g:, 'fujjitive_legacy_commands', 0)
  exe 'command! -bar -bang -nargs=0 Gremove exe fujjitive#RemoveCommand(<line1>, <count>, +"<range>", <bang>0, "<mods>", <q-args>)'
        \ '|echohl WarningMSG|echomsg ":Gremove is deprecated in favor of :GRemove"|echohl NONE'
elseif exists(':Gremove') != 2 && !exists('g:fujjitive_legacy_commands')
  exe 'command! -bar -bang -nargs=0 Gremove echoerr ":Gremove has been removed in favor of :GRemove"'
endif
if exists(':Gdelete') != 2 && get(g:, 'fujjitive_legacy_commands', 0)
  exe 'command! -bar -bang -nargs=0 Gdelete exe fujjitive#DeleteCommand(<line1>, <count>, +"<range>", <bang>0, "<mods>", <q-args>)'
        \ '|echohl WarningMSG|echomsg ":Gdelete is deprecated in favor of :GDelete"|echohl NONE'
elseif exists(':Gdelete') != 2 && !exists('g:fujjitive_legacy_commands')
  exe 'command! -bar -bang -nargs=0 Gdelete echoerr ":Gdelete has been removed in favor of :GDelete"'
endif
if exists(':Gmove') != 2 && get(g:, 'fujjitive_legacy_commands', 0)
  exe 'command! -bar -bang -nargs=1 -complete=customlist,fujjitive#CompleteObject Gmove   exe fujjitive#MoveCommand(  <line1>, <count>, +"<range>", <bang>0, "<mods>", <q-args>)'
        \ '|echohl WarningMSG|echomsg ":Gmove is deprecated in favor of :GMove"|echohl NONE'
elseif exists(':Gmove') != 2 && !exists('g:fujjitive_legacy_commands')
  exe 'command! -bar -bang -nargs=? -complete=customlist,fujjitive#CompleteObject Gmove'
        \ 'echoerr ":Gmove has been removed in favor of :GMove"'
endif
if exists(':Grename') != 2 && get(g:, 'fujjitive_legacy_commands', 0)
  exe 'command! -bar -bang -nargs=1 -complete=customlist,fujjitive#RenameComplete Grename exe fujjitive#RenameCommand(<line1>, <count>, +"<range>", <bang>0, "<mods>", <q-args>)'
        \ '|echohl WarningMSG|echomsg ":Grename is deprecated in favor of :GRename"|echohl NONE'
elseif exists(':Grename') != 2 && !exists('g:fujjitive_legacy_commands')
  exe 'command! -bar -bang -nargs=? -complete=customlist,fujjitive#RenameComplete Grename'
        \ 'echoerr ":Grename has been removed in favor of :GRename"'
endif

exe 'command! -bar -bang -range=-1 -nargs=* -complete=customlist,fujjitive#CompleteObject GBrowse exe fujjitive#BrowseCommand(<line1>, <count>, +"<range>", <bang>0, "<mods>", <q-args>)'
if exists(':Gbrowse') != 2 && get(g:, 'fujjitive_legacy_commands', 0)
  exe 'command! -bar -bang -range=-1 -nargs=* -complete=customlist,fujjitive#CompleteObject Gbrowse exe fujjitive#BrowseCommand(<line1>, <count>, +"<range>", <bang>0, "<mods>", <q-args>)'
        \ '|if <bang>1|redraw!|endif|echohl WarningMSG|echomsg ":Gbrowse is deprecated in favor of :GBrowse"|echohl NONE'
elseif exists(':Gbrowse') != 2 && !exists('g:fujjitive_legacy_commands')
  exe 'command! -bar -bang -range=-1 -nargs=* -complete=customlist,fujjitive#CompleteObject Gbrowse'
        \ 'echoerr ":Gbrowse has been removed in favor of :GBrowse"'
endif

if v:version < 704
  finish
endif

let g:io_fujjitive = {
      \ 'simplify': function('fujjitive#simplify'),
      \ 'resolve': function('fujjitive#resolve'),
      \ 'getftime': function('fujjitive#getftime'),
      \ 'getfsize': function('fujjitive#getfsize'),
      \ 'getftype': function('fujjitive#getftype'),
      \ 'filereadable': function('fujjitive#filereadable'),
      \ 'filewritable': function('fujjitive#filewritable'),
      \ 'isdirectory': function('fujjitive#isdirectory'),
      \ 'getfperm': function('fujjitive#getfperm'),
      \ 'setfperm': function('fujjitive#setfperm'),
      \ 'readfile': function('fujjitive#readfile'),
      \ 'writefile': function('fujjitive#writefile'),
      \ 'glob': function('fujjitive#glob'),
      \ 'delete': function('fujjitive#delete'),
      \ 'Real': function('FujjitiveReal')}

augroup fujjitive
  autocmd!

  autocmd BufNewFile,BufReadPost *
        \ if exists('b:jj_dir') && b:jj_dir =~# '^$\|' . s:bad_jj_dir |
        \   unlet b:jj_dir |
        \ endif
  autocmd FileType           netrw
        \ if exists('b:jj_dir') && b:jj_dir =~# '^$\|' . s:bad_jj_dir |
        \   unlet b:jj_dir |
        \ endif
  autocmd BufFilePost            *  unlet! b:jj_dir

  autocmd FileType git
        \ call fujjitive#MapCfile()
  autocmd FileType gitcommit
        \ call fujjitive#MapCfile('fujjitive#MessageCfile()')
  autocmd FileType git,gitcommit
        \ if &foldtext ==# 'foldtext()' |
        \    setlocal foldtext=fujjitive#Foldtext() |
        \ endif
  autocmd FileType fujjitive
        \ call fujjitive#MapCfile('fujjitive#PorcelainCfile()')
  autocmd FileType gitrebase
        \ let &l:include = '^\%(pick\|squash\|edit\|reword\|fixup\|drop\|[pserfd]\)\>' |
        \ if &l:includeexpr !~# 'Fujjitive' |
        \   let &l:includeexpr = 'v:fname =~# ''^\x\{4,\}$'' && len(FujjitiveJJDir()) ? FujjitiveFind(v:fname) : ' .
        \     (len(&l:includeexpr) ? &l:includeexpr : 'v:fname') |
        \ endif |
        \ let b:undo_ftplugin = get(b:, 'undo_ftplugin', 'exe') . '|setl inex= inc='

  autocmd BufReadCmd index{,.lock} nested
        \ if FujjitiveIsJJDir(expand('<amatch>:p:h')) |
        \   let b:jj_dir = s:Slash(expand('<amatch>:p:h')) |
        \   exe fujjitive#BufReadStatus(v:cmdbang) |
        \   echohl WarningMSG |
        \   echo "fujjitive: Direct editing of .jj/" . expand('%:t') . " is deprecated" |
        \   echohl NONE |
        \ elseif filereadable(expand('<amatch>')) |
        \   silent doautocmd BufReadPre |
        \   keepalt noautocmd read <amatch> |
        \   silent 1delete_ |
        \   silent doautocmd BufReadPost |
        \ else |
        \   silent doautocmd BufNewFile |
        \ endif

  autocmd BufReadCmd   fujjitive://*          nested exe fujjitive#BufReadCmd() |
        \ if &path =~# '^\.\%(,\|$\)' |
        \   let &l:path = substitute(&path, '^\.,\=', '', '') |
        \ endif
  autocmd BufWriteCmd  fujjitive://*          nested exe fujjitive#BufWriteCmd()
  autocmd FileReadCmd  fujjitive://*          nested exe fujjitive#FileReadCmd()
  autocmd FileWriteCmd fujjitive://*          nested exe fujjitive#FileWriteCmd()
  if exists('##SourceCmd')
    autocmd SourceCmd     fujjitive://*       nested exe fujjitive#SourceCmd()
  endif

  autocmd User Flags call Hoist('buffer', function('FujjitiveStatusline'))

  autocmd User ProjectionistDetect call s:ProjectionistDetect()
augroup END

nmap <script><silent> <Plug>fujjitive:y<C-G> :<C-U>call setreg(v:register, fujjitive#Object(@%))<CR>
nmap <script> <Plug>fujjitive: <Nop>

if get(g:, 'fujjitive_no_maps')
  finish
endif

function! s:Map(mode, lhs, rhs, flags) abort
  let flags = a:flags . (a:rhs =~# '<Plug>' ? '' : '<script>') . '<nowait>'
  let head = a:lhs
  let tail = ''
  let keys = get(g:, a:mode.'remap', {})
  if len(keys) && type(keys) == type({})
    while !empty(head)
      if has_key(keys, head)
        let head = keys[head]
        if empty(head)
          return
        endif
        break
      endif
      let tail = matchstr(head, '<[^<>]*>$\|.$') . tail
      let head = substitute(head, '<[^<>]*>$\|.$', '', '')
    endwhile
  endif
  if empty(mapcheck(head.tail, a:mode))
    exe a:mode.'map' flags head.tail a:rhs
  endif
endfunction

call s:Map('c', '<C-R><C-G>', 'fnameescape(fujjitive#Object(@%))', '<expr>')
call s:Map('n', 'y<C-G>', ':<C-U>call setreg(v:register, fujjitive#Object(@%))<CR>', '<silent>')
