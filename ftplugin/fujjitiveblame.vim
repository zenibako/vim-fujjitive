if exists("b:did_ftplugin") || !exists("*FujjitiveJJDir")
  finish
endif
let b:did_ftplugin = 1

call fujjitive#BlameFileType()
