if exists("b:current_syntax")
  finish
endif

syn sync fromstart
syn spell notoplevel

syn include @fujjitiveDiff syntax/diff.vim

syn match fujjitiveHeader /^[A-Z][a-z][^:]*:/
syn match fujjitiveHeader /^Working copy:/ nextgroup=fujjitiveHash,fujjitiveChangeId,fujjitiveSymbolicRef skipwhite
syn match fujjitiveHeader /^Parent:/ nextgroup=fujjitiveHash,fujjitiveChangeId,fujjitiveSymbolicRef skipwhite
syn match fujjitiveHelpHeader /^Help:/ nextgroup=fujjitiveHelpTag skipwhite
syn match fujjitiveHelpTag    /\S\+/ contained

syn region fujjitiveSection start=/^\%(.*(\d\++\=)$\)\@=/ contains=fujjitiveHeading end=/^$/ fold
syn cluster fujjitiveSection contains=fujjitiveSection
syn match fujjitiveHeading /^[A-Z][a-z][^:]*\ze (\d\++\=)$/ contains=fujjitivePreposition contained nextgroup=fujjitiveCount skipwhite
syn match fujjitiveCount /(\d\++\=)/hs=s+1,he=e-1 contained
syn match fujjitivePreposition /\<\%([io]nto\|from\|to\|Rebasing\%( detached\)\=\)\>/ transparent contained nextgroup=fujjitiveHash,fujjitiveChangeId,fujjitiveSymbolicRef skipwhite

syn match fujjitiveInstruction /^\l\l\+\>/ contained containedin=@fujjitiveSection nextgroup=fujjitiveHash,fujjitiveChangeId skipwhite
syn match fujjitiveDone /^done\>/ contained containedin=@fujjitiveSection nextgroup=fujjitiveHash,fujjitiveChangeId skipwhite
syn match fujjitiveStop /^stop\>/ contained containedin=@fujjitiveSection nextgroup=fujjitiveHash,fujjitiveChangeId skipwhite
syn match fujjitiveModifier /^[MADRCU?]\{1,2} / contained containedin=@fujjitiveSection
syn match fujjitiveSymbolicRef /\.\@!\%(\.\.\@!\|[^[:space:][:cntrl:]\:.]\)\+\.\@<!/ contained

" Hex commit hashes (git-style, [0-9a-f])
syn match fujjitiveHash /^\x\{4,\}\S\@!/ contained containedin=@fujjitiveSection
syn match fujjitiveHash /\S\@<!\x\{4,\}\S\@!/ contained

" JJ change IDs ([k-z]) — displayed as the shortest unique prefix
syn match fujjitiveChangeId /^[k-z]\+\S\@!/ contained containedin=@fujjitiveSection
syn match fujjitiveChangeId /\S\@<![k-z]\+\S\@!/ contained

syn region fujjitiveHunk start=/^\%(@@\+ -\)\@=/ end=/^\%([A-Za-z?@]\|$\)\@=/ contains=diffLine,diffRemoved,diffAdded,diffNoEOL containedin=@fujjitiveSection fold

" Named sections — each gets a region, modifier, cluster entry, and heading.
" Sections with simple single-word names that share a generic heading pattern.
for s:section in ['Untracked', 'Unpushed', 'Unpulled']
  exe 'syn region fujjitive' . s:section . 'Section start=/^\%(' . s:section . ' .*(\d\++\=)$\)\@=/ contains=fujjitive' . s:section . 'Heading end=/^$/ fold'
  exe 'syn match fujjitive' . s:section . 'Modifier /^[MADRCU?] / contained containedin=fujjitive' . s:section . 'Section'
  exe 'syn cluster fujjitiveSection add=fujjitive' . s:section . 'Section'
  exe 'syn match fujjitive' . s:section . 'Heading /^[A-Z][a-z][^:]*\ze (\d\++\=)$/ contains=fujjitivePreposition contained nextgroup=fujjitiveCount skipwhite'
endfor
unlet s:section

" Sections with fixed display labels that need explicit heading patterns.
" Each entry is [InternalName, 'Display label'].
for [s:name, s:label] in [['WorkingCopy', 'Changes'], ['Ancestors', 'Ancestors'], ['OtherMutable', 'Other mutable']]
  exe 'syn region fujjitive' . s:name . 'Section start=/^\%(' . s:label . ' .*(\d\++\=)$\)\@=/ contains=fujjitive' . s:name . 'Heading end=/^$/ fold'
  exe 'syn match fujjitive' . s:name . 'Modifier /^[MADRCU?] / contained containedin=fujjitive' . s:name . 'Section'
  exe 'syn cluster fujjitiveSection add=fujjitive' . s:name . 'Section'
  exe 'syn match fujjitive' . s:name . 'Heading /^' . s:label . '\ze (\d\++\=)$/ contained nextgroup=fujjitiveCount skipwhite'
endfor
unlet s:name s:label

" Bookmarks section — has bookmark-name matching instead of a file modifier.
syn region fujjitiveBookmarksSection start=/^\%(Bookmarks .*(\d\++\=)$\)\@=/ contains=fujjitiveBookmarksHeading end=/^$/ fold
syn cluster fujjitiveSection add=fujjitiveBookmarksSection
syn match fujjitiveBookmarksHeading /^Bookmarks\ze (\d\++\=)$/ contained nextgroup=fujjitiveCount skipwhite
syn match fujjitiveBookmarkName /^\S\+/ contained containedin=fujjitiveBookmarksSection nextgroup=fujjitiveChangeId,fujjitiveHash skipwhite

" Markers for jj-specific commit metadata in log sections
syn match fujjitiveEmpty /(empty)/ contained containedin=@fujjitiveSection
syn match fujjitiveConflict /(conflict)/ contained containedin=@fujjitiveSection

hi def link fujjitiveHelpHeader fujjitiveHeader
hi def link fujjitiveHeader Label
hi def link fujjitiveHelpTag Tag
hi def link fujjitiveHeading PreProc
hi def link fujjitiveUntrackedHeading PreCondit
hi def link fujjitiveWorkingCopyHeading Macro
hi def link fujjitiveAncestorsHeading PreProc
hi def link fujjitiveOtherMutableHeading PreProc
hi def link fujjitiveUnpushedHeading PreProc
hi def link fujjitiveUnpulledHeading PreProc
hi def link fujjitiveBookmarksHeading PreProc
hi def link fujjitiveBookmarkName Function
hi def link fujjitiveModifier Type
hi def link fujjitiveUntrackedModifier StorageClass
hi def link fujjitiveWorkingCopyModifier Structure
hi def link fujjitiveInstruction Type
hi def link fujjitiveStop Function
hi def link fujjitiveHash Identifier
hi def link fujjitiveChangeId Identifier
hi def link fujjitiveSymbolicRef Function
hi def link fujjitiveCount Number
hi def link fujjitiveEmpty Comment
hi def link fujjitiveConflict WarningMsg

let b:current_syntax = "fujjitive"
