if exists("b:current_syntax") || !exists("*FujjitiveJJDir")
  finish
endif

call fujjitive#BlameSyntax()

let b:current_syntax = "fujjitiveblame"
