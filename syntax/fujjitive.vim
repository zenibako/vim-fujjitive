if exists("b:current_syntax")
  finish
endif

syn sync fromstart
syn spell notoplevel

syn include @fujjitiveDiff syntax/diff.vim

syn match fujjitiveHeader /^[A-Z][a-z][^:]*:/
syn match fujjitiveHeader /^Working copy:/ nextgroup=fujjitiveHash,fujjitiveSymbolicRef skipwhite
syn match fujjitiveHeader /^Parent:/ nextgroup=fujjitiveHash,fujjitiveSymbolicRef skipwhite
syn match fujjitiveHelpHeader /^Help:/ nextgroup=fujjitiveHelpTag skipwhite
syn match fujjitiveHelpTag    /\S\+/ contained

syn region fujjitiveSection start=/^\%(.*(\d\++\=)$\)\@=/ contains=fujjitiveHeading end=/^$/ fold
syn cluster fujjitiveSection contains=fujjitiveSection
syn match fujjitiveHeading /^[A-Z][a-z][^:]*\ze (\d\++\=)$/ contains=fujjitivePreposition contained nextgroup=fujjitiveCount skipwhite
syn match fujjitiveCount /(\d\++\=)/hs=s+1,he=e-1 contained
syn match fujjitivePreposition /\<\%([io]nto\|from\|to\|Rebasing\%( detached\)\=\)\>/ transparent contained nextgroup=fujjitiveHash,fujjitiveSymbolicRef skipwhite

syn match fujjitiveInstruction /^\l\l\+\>/ contained containedin=@fujjitiveSection nextgroup=fujjitiveHash skipwhite
syn match fujjitiveDone /^done\>/ contained containedin=@fujjitiveSection nextgroup=fujjitiveHash skipwhite
syn match fujjitiveStop /^stop\>/ contained containedin=@fujjitiveSection nextgroup=fujjitiveHash skipwhite
syn match fujjitiveModifier /^[MADRCU?]\{1,2} / contained containedin=@fujjitiveSection
syn match fujjitiveSymbolicRef /\.\@!\%(\.\.\@!\|[^[:space:][:cntrl:]\:.]\)\+\.\@<!/ contained
syn match fujjitiveHash /^\x\{4,\}\S\@!/ contained containedin=@fujjitiveSection
syn match fujjitiveHash /\S\@<!\x\{4,\}\S\@!/ contained

syn region fujjitiveHunk start=/^\%(@@\+ -\)\@=/ end=/^\%([A-Za-z?@]\|$\)\@=/ contains=diffLine,diffRemoved,diffAdded,diffNoEOL containedin=@fujjitiveSection fold

for s:section in ['Untracked', 'Unstaged']
  exe 'syn region fujjitive' . s:section . 'Section start=/^\%(' . s:section . ' .*(\d\++\=)$\)\@=/ contains=fujjitive' . s:section . 'Heading end=/^$/ fold'
  exe 'syn match fujjitive' . s:section . 'Modifier /^[MADRCU?] / contained containedin=fujjitive' . s:section . 'Section'
  exe 'syn cluster fujjitiveSection add=fujjitive' . s:section . 'Section'
  exe 'syn match fujjitive' . s:section . 'Heading /^[A-Z][a-z][^:]*\ze (\d\++\=)$/ contains=fujjitivePreposition contained nextgroup=fujjitiveCount skipwhite'
endfor
unlet s:section

hi def link fujjitiveHelpHeader fujjitiveHeader
hi def link fujjitiveHeader Label
hi def link fujjitiveHelpTag Tag
hi def link fujjitiveHeading PreProc
hi def link fujjitiveUntrackedHeading PreCondit
hi def link fujjitiveUnstagedHeading Macro
hi def link fujjitiveModifier Type
hi def link fujjitiveUntrackedModifier StorageClass
hi def link fujjitiveUnstagedModifier Structure
hi def link fujjitiveInstruction Type
hi def link fujjitiveStop Function
hi def link fujjitiveHash Identifier
hi def link fujjitiveSymbolicRef Function
hi def link fujjitiveCount Number

let b:current_syntax = "fujjitive"
