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

" Sections with simple single-word names
for s:section in ['Untracked', 'Unpushed', 'Unpulled']
  exe 'syn region fujjitive' . s:section . 'Section start=/^\%(' . s:section . ' .*(\d\++\=)$\)\@=/ contains=fujjitive' . s:section . 'Heading end=/^$/ fold'
  exe 'syn match fujjitive' . s:section . 'Modifier /^[MADRCU?] / contained containedin=fujjitive' . s:section . 'Section'
  exe 'syn cluster fujjitiveSection add=fujjitive' . s:section . 'Section'
  exe 'syn match fujjitive' . s:section . 'Heading /^[A-Z][a-z][^:]*\ze (\d\++\=)$/ contains=fujjitivePreposition contained nextgroup=fujjitiveCount skipwhite'
endfor
unlet s:section

" 'Working copy changes' section (display label for the internal 'Unstaged' key)
syn region fujjitiveWorkingCopySection start=/^\%(Working copy changes .*(\d\++\=)$\)\@=/ contains=fujjitiveWorkingCopyHeading end=/^$/ fold
syn match fujjitiveWorkingCopyModifier /^[MADRCU?] / contained containedin=fujjitiveWorkingCopySection
syn cluster fujjitiveSection add=fujjitiveWorkingCopySection
syn match fujjitiveWorkingCopyHeading /^Working copy changes\ze (\d\++\=)$/ contained nextgroup=fujjitiveCount skipwhite

" 'Current branch' section — mutable ancestors of the working copy
syn region fujjitiveCurrentBranchSection start=/^\%(Current branch .*(\d\++\=)$\)\@=/ contains=fujjitiveCurrentBranchHeading end=/^$/ fold
syn match fujjitiveCurrentBranchModifier /^[MADRCU?] / contained containedin=fujjitiveCurrentBranchSection
syn cluster fujjitiveSection add=fujjitiveCurrentBranchSection
syn match fujjitiveCurrentBranchHeading /^Current branch\ze (\d\++\=)$/ contained nextgroup=fujjitiveCount skipwhite

" 'Other mutable' section — mutable changes not on the current branch
syn region fujjitiveOtherMutableSection start=/^\%(Other mutable .*(\d\++\=)$\)\@=/ contains=fujjitiveOtherMutableHeading end=/^$/ fold
syn match fujjitiveOtherMutableModifier /^[MADRCU?] / contained containedin=fujjitiveOtherMutableSection
syn cluster fujjitiveSection add=fujjitiveOtherMutableSection
syn match fujjitiveOtherMutableHeading /^Other mutable\ze (\d\++\=)$/ contained nextgroup=fujjitiveCount skipwhite

" 'Bookmarks' section — local bookmarks and their targets
syn region fujjitiveBookmarksSection start=/^\%(Bookmarks .*(\d\++\=)$\)\@=/ contains=fujjitiveBookmarksHeading end=/^$/ fold
syn cluster fujjitiveSection add=fujjitiveBookmarksSection
syn match fujjitiveBookmarksHeading /^Bookmarks\ze (\d\++\=)$/ contained nextgroup=fujjitiveCount skipwhite
" Bookmark name is the first word on entry lines (not the heading) within the section
syn match fujjitiveBookmarkName /^\S\+/ contained containedin=fujjitiveBookmarksSection nextgroup=fujjitiveHash skipwhite

" Markers for jj-specific commit metadata in log sections
syn match fujjitiveEmpty /(empty)/ contained containedin=@fujjitiveSection
syn match fujjitiveConflict /(conflict)/ contained containedin=@fujjitiveSection

hi def link fujjitiveHelpHeader fujjitiveHeader
hi def link fujjitiveHeader Label
hi def link fujjitiveHelpTag Tag
hi def link fujjitiveHeading PreProc
hi def link fujjitiveUntrackedHeading PreCondit
hi def link fujjitiveWorkingCopyHeading Macro
hi def link fujjitiveCurrentBranchHeading PreProc
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
hi def link fujjitiveSymbolicRef Function
hi def link fujjitiveCount Number
hi def link fujjitiveEmpty Comment
hi def link fujjitiveConflict WarningMsg

let b:current_syntax = "fujjitive"
