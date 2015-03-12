" Vim syntax file
" Language:     Octascript
" Last Change:  2014 Nov 22
"
" put in .vim/syntax/octascript.vim
" and in .vim/ftdetect/octascript.vim write something like:
" au BufRead,BufNewFile *.oct set filetype=octascript

if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

" NOTE that the order generally matters
" The order of the following is important due to precedence, they are applied
" in reverse order and the first match (read: the last in this list) is used.

syn match     octaScriptOperator     /[-=!+/*<>%&|^~?:.,;#\\@]/

syn keyword   octaScriptKeyword var import from export as
syn keyword   octaScriptKeyword func
syn keyword   octaScriptKeyword if else
syn keyword   octaScriptKeyword in to by
syn keyword   octaScriptKeyword repeat until for while
syn keyword   octaScriptKeyword break continue goto
syn keyword   octaScriptKeyword try
syn keyword   octaScriptKeyword typeof
syn keyword   octaScriptKeyword enum
syn keyword   octaScriptKeyword print raise rec return
syn keyword   octaScriptKeyword self

syn keyword   octaScriptMetaFun __add __call __concat __div __eq __index
syn keyword   octaScriptMetaFun __le __lt __metatable __mode __mul __newindex
syn keyword   octaScriptMetaFun __pairs __pow __sub
syn keyword   octaScriptMetaFun __tostring __unm

syn region    octaScriptComment     start="//"  end="$" contains=octaScriptTodo keepend
syn region    octaScriptCommentMult start="/\*" end="\*/" contains=octaScriptCommentMult,octaScriptTodo keepend extend
syn keyword   octaScriptTodo        TODO FIXME XXX

"syn match     octaScriptModPath      "\w\(\w\)*::[^<]"he=e-1,me=e-1
"syn match     octaScriptModPathSep   "::"

syn match     octaScriptFuncCall     "\w\(\w\)*("he=e-1,me=e-1
syn region    octaScriptParenthesis  start='(' end=')' keepend extend contains=TOP
syn region    octaScriptParenthesis  start='\[' end=']' keepend extend contains=TOP
syn region    octaScriptParenthesis  start='{' end='}' keepend extend contains=TOP

syn region    octaScriptSglQString   start=/\z(['"]\)/rs=e+1 skip=/\\\\\|\\\z1/ end=/\z1/re=e-1
\                                    keepend extend contains=octaScriptNewline,@octaScriptEscapeSeq
syn region    octaScriptTriQString   start=/\z(["']\{3\}\)/rs=e+3 skip=/\\\\\|\\\z1/ end=/\z1/re=e-3
\                                    keepend extend contains=octaScriptNewline,@octaScriptEscapeSeq
syn region    octaScriptSglQStringE  matchgroup=PreProc start=/[eE]\z(['"]\)/rs=e-1 skip=/\\\\\|\\\z1/ matchgroup=String end=/\z1/re=e-1
\                                    keepend extend contains=octaScriptNewline,@octaScriptEscapeSeq,@octaScriptInterpolate
syn region    octaScriptTriQStringE  matchgroup=PreProc start=/[eE]\z(["']\{3\}\)/rs=e-3 skip=/\\\\\|\\\z1/ matchgroup=String end=/\z1/re=e-3
\                                    keepend extend contains=octaScriptNewline,@octaScriptEscapeSeq,@octaScriptInterpolate
syn region    octaScriptSglQStringR  matchgroup=PreProc start=/[rR]\z(['"]\)/rs=e-1 skip=/\\\\\|\\\z1/ matchgroup=String end=/\z1/re=e-1
\                                    keepend extend contains=octaScriptNewline
syn region    octaScriptTriQStringR  matchgroup=PreProc start=/[rR]\z(["']\{3\}\)/rs=e-3 skip=/\\\\\|\\\z1/ matchgroup=String end=/\z1/re=e-3
\                                    keepend extend contains=octaScriptNewline
syn region    octaScriptSglQStringRE matchgroup=PreProc start=/\([eE][rR]\|[rR][eE]\)\z(['"]\)/rs=e-1 skip=/\\\\\|\\\z1/ matchgroup=String end=/\z1/re=e-1
\                                    keepend extend contains=octaScriptNewline,@octaScriptInterpolate
syn region    octaScriptTriQStringRE matchgroup=PreProc start=/\([eE][rR]\|[rR][eE]\)\z(["']\{3\}\)/rs=e-3 skip=/\\\\\|\\\z1/ matchgroup=String end=/\z1/re=e-3
\                                    keepend extend contains=octaScriptNewline,@octaScriptInterpolate
syn match     octaScriptNewline      /\\$/ contained
syn match     octaScriptIVar         /[^\\]\$[A-Za-z_][A-Za-z0-9_]*/hs=s+1 contained
syn region    octaScriptIExpr        matchgroup=Statement start=/[^\\]\$(/ms=s+1 matchgroup=Statement end=')'
\                                    keepend contains=TOP
syn cluster   octaScriptInterpolate  contains=octaScriptIVar,octaScriptIExpr

" Yes they're decimal not octal
syn match     octaScriptEscapeDec    /\\[0-9]/ contained
syn match     octaScriptEscapeDec    /\\[0-9][0-9]/ contained
syn match     octaScriptEscapeDec    /\\25[0-5]/ contained
syn match     octaScriptEscapeDec    /\\2[0-4][0-9]/ contained
syn match     octaScriptEscapeDec    /\\[0-1][0-9][0-9]/ contained
syn match     octaScriptEscapeHex    /\\x[0-9a-fA-F][0-9a-fA-F]/ contained
syn match     octaScriptEscapeStd    /\\[abfnrtv]/ contained
syn cluster   octaScriptEscapeSeq    contains=octaScriptEscapeStd,octaScriptEscapeHex,octaScriptEscapeDec

syn keyword   octaScriptKeyword      true false null undef
syn match     octaScriptNumber       "\<[0-9_]\+\([uU]\?[lL][lL]\|[iI]\)\?\>"
syn match     octaScriptNumber       "\<0x[0-9a-fA-F_]\+\([uU]\?[lL][lL]\|[iI]\)\?\>"
syn match     octaScriptNumber       "\<0x[01_]\+\([uU]\?[lL][lL]\|[iI]\)\?\>"
syn match     octaScriptNumber       "\<[0-9][0-9_]*\([eE][-+]\?[0-9_]\+\)\?[iI]\?\>"
syn match     octaScriptNumber       "\<\([0-9][0-9_]*\)\?\.[0-9_]\+\([eE][-+]\?[0-9_]\+\)\?[iI]\?\>"

hi def link octaScriptKeyword      Keyword
hi def link octaScriptComment      Comment
hi def link octaScriptCommentMult  Comment
hi def link octaScriptTodo         Todo
hi def link octaScriptModPath      Include
hi def link octaScriptFuncCall     Function
hi def link octaScriptTriQString   String
hi def link octaScriptSglQString   String
hi def link octaScriptTriQStringE  String
hi def link octaScriptSglQStringE  String
hi def link octaScriptTriQStringR  String
hi def link octaScriptSglQStringR  String
hi def link octaScriptTriQStringRE String
hi def link octaScriptSglQStringRE String
hi def link octaScriptNewline      Comment
hi def link octaScriptBadNewline   Error
hi def link octaScriptIVar         PreProc
hi def link octaScriptEscapeStd    SpecialChar
hi def link octaScriptEscapeDec    SpecialChar
hi def link octaScriptEscapeHex    SpecialChar
hi def link octaScriptBoolean      Boolean
hi def link octaScriptNumber       Number
hi def link octaScriptMetaFun      Function
hi def link octaScriptOperator     Operator

let b:current_syntax = "octascript"
