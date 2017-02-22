"===============================================================================
"
"          File:  verilog-support.vim
" 
"   Description:  verilog-support.vim implements a UVM/SV IDE for Vim/gVim. It is
"                 intended to assist in coding UVM classes in a consistent
"                 style and to aid in using some of the more esoteric and
"                 rarely used constructs in UVM. 
" 
"   VIM Version:  7.0+
"        Author:  Jeff McNeal <jeff.mcneal@verilab.com>
"                 Based on perl-support.vim by:
"                 Dr.-Ing. Fritz Mehner <mehner.fritz@fh-swf.de>
"  Organization:  
"       Version:  1.0
"       Created:  08/02/2016 09:06
"      Revision:  ---
"       License:  GPL version 2
"===============================================================================
"
" Prevent duplicate loading:
"
if exists("g:SV_PluginVersion")
    finish
endif
let g:SV_PluginVersion = "0.5"

"===  FUNCTION  ================================================================
"          NAME:  SV_SetGlobalVariable     {{{1
"   DESCRIPTION:  Define a global variable and assign a default value if nor
"                 already defined
"    PARAMETERS:  name - global variable
"                 default - default value
"===============================================================================
function! s:SV_SetGlobalVariable ( name, default )
  if !exists('g:'.a:name)
    exe 'let g:'.a:name."  = '".a:default."'"
    else
        " check for an empty initialization
        exe 'let    val    = g:'.a:name
        if empty(val)
            exe 'let g:'.a:name."  = '".a:default."'"
        endif
  endif
endfunction   " ---------- end of function  s:SV_SetGlobalVariable  ----------

"===  FUNCTION  ================================================================
"          NAME:  SV_SetLocalVariable     {{{1
"   DESCRIPTION:  Assign a value to a local variable if a corresponding global
"                 variable exists
"    PARAMETERS:  name - name of a global variable
"===============================================================================
function! s:SV_SetLocalVariable ( name )
  if exists('g:'.a:name)
    exe 'let s:'.a:name.'  = g:'.a:name
  endif
endfunction   " ---------- end of function  s:SV_SetLocalVariable  ----------

"------------------------------------------------------------------------------
"
"  Look for global variables (if any), to override the defaults.
"
call s:SV_SetGlobalVariable( "SV_MenuHeader", 'yes')
call s:SV_SetGlobalVariable( "SV_OutputGvim", 'vim')

call s:SV_SetLocalVariable('SV_UseToolbox')

"------------------------------------------------------------------------------
"
" Platform specific items:
" - plugin directory
" - characters that must be escaped for filenames
"
let s:MSWIN     = has("win16") || has("win32")   || has("win64")    || has("win95")
let s:UNIX      = has("unix")  || has("macunix") || has("win32unix")
let s:SV_ToolboxDir  = []
"if  s:MSWIN
  " ==========  MS Windows  ======================================================
"else
  " ==========  Linux/Unix  ======================================================
    "
    let g:SV_PluginDir = expand("<sfile>:p:h:h")
    "
    if match( expand("<sfile>"), resolve( expand("$HOME") ) ) == 0
        " USER INSTALLATION ASSUMED
        let g:SV_Installation         = 'local'
        let s:SV_LocalTemplateFile    =   g:SV_PluginDir.'/verilog-support/templates/Templates'
        let s:SV_ToolboxDir          += [ g:SV_PluginDir.'/autoload/mmtoolbox/' ]
    else
        "  Not yet, but in the future
        "  " SYSTEM WIDE INSTALLATION
        "  let g:SV_Installation         = 'system'
        "  let s:SV_GlobalTemplateFile   = g:SV_PluginDir.'/perl-support/templates/Templates'
        "  let s:SV_LocalTemplateFile    = $HOME.'/.vim/perl-support/templates/Templates'
        "  let s:SV_ToolboxDir             += [
                    "  \    g:SV_PluginDir.'/autoload/mmtoolbox/',
                    "  \    $HOME.'/.vim/autoload/mmtoolbox/' ]
    endif
    "
    " ==============================================================================
"endif

"  Module global variables (with default values) which can be overridden.     {{{1
"
let s:SV_LoadMenus             = 'yes'        " display the menus ?
let s:SV_TemplateOverriddenMsg = 'no'
let s:SV_Ctrl_j                = 'on'
"
let s:SV_LineEndCommColDefault = 69
let s:SV_LineEndCommColDefault = 69
let s:SVStartComment           = '\/\/'       " This is used in a VIM expression, so needs to be escaped
let s:SV_GuiSnippetBrowser     = 'gui'        " gui / commandline
let s:SV_GuiTemplateBrowser    = 'gui'        " gui / explorer / commandline
let s:SV_CreateMenusDelayed    = 'yes'
"
let s:SV_InsertFileHeader      = 'yes'
"
call s:SV_SetGlobalVariable ( 'SV_MapLeader', '' )
let s:SV_RootMenu              = '&Verilog'
"
" TODO: add NaturalDocs as a toolbox option.
" TODO: add Doxygen as a toolbox option.
let s:SV_UseToolbox            = 'no'
call s:SV_SetGlobalVariable ( 'SV_UseTool_make',  'no' )
call s:SV_SetGlobalVariable ( 'SV_UseTool_ND',    'no' )

"------------------------------------------------------------------------------
"  Control variables (not user configurable)
"------------------------------------------------------------------------------
"
let s:SV_MenuVisible           = 'no'
let s:SV_TemplateJumpTarget    = ''

let s:MsgInsNotAvail           = "insertion not available for a fold"
let s:SV_saved_global_option   = {}

"===  FUNCTION  ================================================================
"          NAME:  SV_Input     {{{1
"   DESCRIPTION:  Input after a highlighted prompt
"    PARAMETERS:  prompt - prompt
"                 text   - default reply
"                 ...    - completion (optional)
"       RETURNS:
"===============================================================================
function! SV_Input ( prompt, text, ... )
    echohl Search                                         " highlight prompt
    call inputsave()                                      " preserve typeahead
    if a:0 == 0 || empty(a:1)
        let retval    =input( a:prompt, a:text )
    else
        let retval    =input( a:prompt, a:text, a:1 )
    endif
    call inputrestore()                                   " restore typeahead
    echohl None                                           " reset highlighting
    let retval  = substitute( retval, '^\s\+', "", "" )   " remove leading whitespaces
    let retval  = substitute( retval, '\s\+$', "", "" )   " remove trailing whitespaces
    return retval
endfunction    " ----------  end of function SV_Input ----------

" patterns to ignore when adjusting line-end comments (incomplete):
" some heuristics used (only Perl can parse Perl)
let    s:AlignRegex    = [
    \    '\$#' ,
    \    ]
"orig...
"let    s:AlignRegex    = [
"    \    '\$#' ,         " dollar# is not a comment,
"    \    '"\%(\\.\|[^"]\)*"'  ,
"    \    '`[^`]\+`' ,
"    \    '\%(m\|qr\)#[^#]\+#' ,
"    \    '\%(m\|qr\)\?\([\?\/]\).*\1[imsxg]*'  ,
"    \    '\%(m\|qr\)\([[:punct:]]\).*\2[imsxg]*'  ,
"    \    '\%(m\|qr\){.*}[imsxg]*'  ,
"    \    '\%(m\|qr\)(.*)[imsxg]*'  ,
"    \    '\%(m\|qr\)\[.*\][imsxg]*'  ,
"    \    '\%(s\|tr\)#[^#]\+#[^#]\+#' ,
"    \    '\%(s\|tr\){[^}]\+}{[^}]\+}' ,
"    \    ]
"    ...orig

"===  FUNCTION  ================================================================
"          NAME:  SV_GetLineEndCommCol     {{{1
"   DESCRIPTION:  get end-of-line comment position
"===============================================================================
function! SV_GetLineEndCommCol ()
  let actcol  = virtcol(".")
  if actcol+1 == virtcol("$")
    let b:SV_LineEndCommentColumn = ''
		while match( b:SV_LineEndCommentColumn, '^\s*\d\+\s*$' ) < 0
			let b:SV_LineEndCommentColumn = SV_Input( 'start line-end comment at virtual column : ', actcol, '' )
		endwhile
  else
    let b:SV_LineEndCommentColumn = virtcol(".")
  endif
  echomsg "line end comments will start at column  ".b:SV_LineEndCommentColumn
endfunction   " ---------- end of function  SV_GetLineEndCommCol  ----------
"
"===  FUNCTION  ================================================================
"          NAME:  SV_EndOfLineComment     {{{1
"   DESCRIPTION:  apply single end-of-line comment
"===============================================================================
function! SV_EndOfLineComment ( ) range
	if !exists("b:SV_LineEndCommentColumn")
		let	b:SV_LineEndCommentColumn	= s:SV_LineEndCommColDefault
	endif
	" ----- trim whitespaces -----
	exe a:firstline.','.a:lastline.'s/\s*$//'

	for line in range( a:lastline, a:firstline, -1 )
		silent exe ":".line
		if getline(line) !~ '^\s*$'
			let linelength	= virtcol( [line, "$"] ) - 1
			let	diff				= 1
			if linelength < b:SV_LineEndCommentColumn
				let diff	= b:SV_LineEndCommentColumn -1 -linelength
			endif
			exe "normal!	".diff."A "
			call mmtemplates#core#InsertTemplate(g:SV_Templates, 'Comments.end-of-line-comment')
		endif
	endfor
endfunction		" ---------- end of function  SV_EndOfLineComment  ----------

"===  FUNCTION  ================================================================
"          NAME:  SV_AlignLineEndComm     {{{1
"   DESCRIPTION:  align end-of-line comments
"===============================================================================
function! SV_AlignLineEndComm ( ) range
    "
    " comment character (for use in regular expression)
    let cc = '//'                     " start of a Verilog comment
    "
    " patterns to ignore when adjusting line-end comments (may be incomplete):
    let align_regex    = join( s:AlignRegex, '\|' )
    "
    " local position
    if !exists( 'b:SV_LineEndCommentColumn' )
        let b:SV_LineEndCommentColumn = s:SV_LineEndCommColDefault
    endif
    let correct_idx = b:SV_LineEndCommentColumn
    "
    " === plug-in specific code ends here                 ===
    " === the behavior is governed by the variables above ===
    "
    " save the cursor position
    let save_cursor = getpos('.')
    "
    for line in range( a:firstline, a:lastline )
        silent exe ':'.line
        "
        let linetxt = getline('.')
        "
        " "pure" comment line left unchanged
        if match ( linetxt, '^\s*'.cc ) == 0
            "echo 'line '.line.': "pure" comment'
            continue
        endif
        "
        let b_idx1 = 1 + match ( linetxt, '\s*'.cc.'.*$', 0 )
        let b_idx2 = 1 + match ( linetxt,       cc.'.*$', 0 )
        "
        " not found?
        if b_idx1 == 0
            "echo 'line '.line.': no end-of-line comment'
            continue
        endif
        "
        " walk through ignored patterns
        let idx_start = 0
        "
        while 1
            let this_start = match ( linetxt, align_regex, idx_start )
            "
            if this_start == -1
                break
            else
                let idx_start = matchend ( linetxt, align_regex, idx_start )
                "echo 'line '.line.': ignoring >>>'.strpart(linetxt,this_start,idx_start-this_start).'<<<'
            endif
        endwhile
        "
        let b_idx1 = 1 + match ( linetxt, '\s*'.cc.'.*$', idx_start )
        let b_idx2 = 1 + match ( linetxt,       cc.'.*$', idx_start )
        "
        " not found?
        if b_idx1 == 0
            "echo 'line '.line.': no end-of-line comment'
            continue
        endif
        "
        call cursor ( line, b_idx2 )
        let v_idx2 = virtcol('.')
        "
        " do b_idx1 last, so the cursor is in the right position for substitute below
        call cursor ( line, b_idx1 )
        let v_idx1 = virtcol('.')
        "
        " already at right position?
        if ( v_idx2 == correct_idx )
            "echo 'line '.line.': already at right position'
            continue
        endif
        " ... or line too long?
        if ( v_idx1 >  correct_idx )
            "echo 'line '.line.': line too long'
            continue
        endif
        "
        " substitute all whitespaces behind the cursor (regex '\%#') and the next character,
        " to ensure the match is at least one character long
        silent exe 'substitute/\%#\s*\(\S\)/'.repeat( ' ', correct_idx - v_idx1 ).'\1/'
        "echo 'line '.line.': adjusted'
        "
    endfor
    "
    " restore the cursor position
    call setpos ( '.', save_cursor )
    "
endfunction        " ---------- end of function  SV_AlignLineEndComm  ----------

"
let s:SV_CmtCounter   = 0
let s:SV_CmtLabel     = "BlockCommentNo_"
"
"===  FUNCTION  ================================================================
"          NAME:  SV_CommentBlock     {{{1
"   DESCRIPTION:  set block of code within /* and */
"    PARAMETERS:  mode - curent edit mode
"===============================================================================
function! SV_CommentBlock (mode)
  "
  let s:SV_CmtCounter = 0
  let save_line         = line(".")
  let actual_line       = 0
  "
  " search for the maximum option number (if any)
  "
  normal! gg
  while actual_line < search( s:SV_CmtLabel."\\d\\+" )
    let actual_line = line(".")
    let actual_opt  = matchstr( getline(actual_line), s:SV_CmtLabel."\\d\\+" )
    let actual_opt  = strpart( actual_opt, strlen(s:SV_CmtLabel),strlen(actual_opt)-strlen(s:SV_CmtLabel))
    if s:SV_CmtCounter < actual_opt
      let s:SV_CmtCounter = actual_opt
    endif
  endwhile
  let s:SV_CmtCounter = s:SV_CmtCounter+1
  silent exe ":".save_line
  "
  if a:mode=='a'
    let zz=      "\n/* begin BlockComment  # ".s:SV_CmtLabel.s:SV_CmtCounter
    let zz= zz."\n\n   end   BlockComment  # ".s:SV_CmtLabel.s:SV_CmtCounter
    let zz= zz."\n*/\n"
    put =zz
  endif

  if a:mode=='v'
    let zz=    "\n/* begin BlockComment  # ".s:SV_CmtLabel.s:SV_CmtCounter."\n\n"
    :'<put! =zz
    let zz=    "\n   end   BlockComment  # ".s:SV_CmtLabel.s:SV_CmtCounter
    let zz= zz."\n*/\n"
    :'>put  =zz
  endif

endfunction    " ----------  end of function SV_CommentBlock ----------
"
"===  FUNCTION  ================================================================
"          NAME:  SV_UncommentBlock     {{{1
"   DESCRIPTION:  uncomment block of code (remove POD commands)
"===============================================================================
function! SV_UncommentBlock ()

  let frstline  = searchpair( '^\/\*\sbegin\s\+BlockComment\s*#\s*'.s:SV_CmtLabel.'\d\+',
      \                       '',
      \                       '^\s*end\s\+BlockComment\s\+#\s*'.s:SV_CmtLabel.'\d\+',
      \                       'bn' )
  if frstline<=0
    echohl WarningMsg | echo 'no comment block/tag found or cursor not inside a comment block'| echohl None
    return
  endif
  let lastline  = searchpair( '^\/\*\sbegin\s\+BlockComment\s*#\s*'.s:SV_CmtLabel.'\d\+',
      \                       '',
      \                       '^\s*end\s\+BlockComment\s\+#\s*'.s:SV_CmtLabel.'\d\+',
      \                       'n' )
  if lastline<=0
    echohl WarningMsg | echo 'no comment block/tag found or cursor not inside a comment block'| echohl None
    return
  endif
  let actualnumber1  = matchstr( getline(frstline), s:SV_CmtLabel."\\d\\+" )
  let actualnumber2  = matchstr( getline(lastline), s:SV_CmtLabel."\\d\\+" )
  if actualnumber1 != actualnumber2
    echohl WarningMsg | echo 'lines '.frstline.', '.lastline.': comment tags do not match'| echohl None
    return
  endif

  let line1 = lastline
  let line2 = lastline
  " empty line before =end
  if match( getline(lastline-1), '^\s*$' ) != -1
    let line1 = line1-1
  endif
  if lastline+1<line("$") && match( getline(lastline+1), '^\s*$' ) != -1
    let line2 = line2+1
  endif
  if lastline+1<line("$") && match( getline(lastline+1), '^\*\/' ) != -1
    let line2 = line2+1
  endif
  silent exe ':'.line1.','.line2.'d'

  let line1 = frstline
  let line2 = frstline
  if frstline>1 && match( getline(frstline-1), '^\s*$' ) != -1
    let line1 = line1-1
  endif
  if match( getline(frstline+1), '^\s*$' ) != -1
    let line2 = line2+1
  endif
  silent exe ':'.line1.','.line2.'d'

endfunction    " ----------  end of function SV_UncommentBlock ----------
"

"===  FUNCTION  ================================================================
"          NAME:  SV_CommentToggle     {{{1
"   DESCRIPTION:  toggle comment
"===============================================================================
function! SV_CommentToggle () range
    let    comment=1                                    "
    for line in range( a:firstline, a:lastline )
        if match( getline(line), "^".s:SVStartComment) == -1                    " no comment
            let comment = 0
            break
        endif
    endfor

    if comment == 0
            exe a:firstline.','.a:lastline."s/^/".s:SVStartComment."/"
    else
            exe a:firstline.','.a:lastline."s/^".s:SVStartComment."//"
    endif

endfunction    " ----------  end of function SV_CommentToggle ----------
"
"===  FUNCTION  ================================================================
"          NAME:  SV_CreateGuiMenus     {{{1
"   DESCRIPTION:  create GUI menus immediate
"    PARAMETERS:  -
"       RETURNS:
"===============================================================================
function! SV_CreateGuiMenus ()
    if s:SV_MenuVisible != 'yes'
        aunmenu <silent> &Tools.Load\ Verilog\ Support
        amenu   <silent> 40.1000 &Tools.-SEP100- :
        amenu   <silent> 40.1160 &Tools.Unload\ Verilog\ Support :call SV_RemoveGuiMenus()<CR>
        call s:SV_RereadTemplates('no')
        call s:SV_InitMenus ()
        let s:SV_MenuVisible = 'yes'
    endif
endfunction    " ----------  end of function SV_CreateGuiMenus  ----------

"===  FUNCTION  ================================================================
"          NAME:  SV_InitMenus     {{{1
"   DESCRIPTION:  initialize the hardcoded menu items
"    PARAMETERS:  -
"       RETURNS:
"===============================================================================
function! s:SV_InitMenus ()
    "
    if ! has ( 'menu' )
        return
    endif
    "
    " Preparation
    call mmtemplates#core#CreateMenus ( 'g:SV_Templates', s:SV_RootMenu, 'do_reset' )
    "
    " get the mapleader (correctly escaped)
    let [ esc_mapl, err ] = mmtemplates#core#Resource ( g:SV_Templates, 'escaped_mapleader' )
    "
    exe 'amenu '.s:SV_RootMenu.'.Verilog  <Nop>'
    exe 'amenu '.s:SV_RootMenu.'.-Sep00- <Nop>'
    "
    "-------------------------------------------------------------------------------
    " menu headers
    "-------------------------------------------------------------------------------

	call mmtemplates#core#CreateMenus ( 'g:SV_Templates', s:SV_RootMenu, 'sub_menu', '&Comments', 'priority', 500 )
	call mmtemplates#core#CreateMenus ( 'g:SV_Templates', s:SV_RootMenu, 'sub_menu', '&Help',     'priority', 1000 )
	if s:SV_UseToolbox == 'yes' && mmtoolbox#tools#Property ( s:SV_Toolbox, 'empty-menu' ) == 0
		call mmtemplates#core#CreateMenus ( 'g:SV_Templates', s:SV_RootMenu, 'sub_menu', '&Tool Box', 'priority', 900 )
	endif

    "===============================================================================================
    "----- Menu : GENERATE MENU ITEMS FROM THE TEMPLATES                              {{{2
    "===============================================================================================
    call mmtemplates#core#CreateMenus ( 'g:SV_Templates', s:SV_RootMenu, 'do_templates' )

    "===============================================================================================
    "----- Menu : Comments                              {{{2
    "===============================================================================================

    let ahead = 'anoremenu <silent> '.s:SV_RootMenu.'.&Comments.'
    let vhead = 'vnoremenu <silent> '.s:SV_RootMenu.'.&Comments.'
    let ihead = 'inoremenu <silent> '.s:SV_RootMenu.'.&Comments.'
    "
    exe ahead.'-Sep02-                                                     <Nop>'
    exe ahead.'end-of-&line\ comment<Tab>'.esc_mapl.'cl                    :call SV_EndOfLineComment()<CR>'
    exe vhead.'end-of-&line\ comment<Tab>'.esc_mapl.'cl                    :call SV_EndOfLineComment()<CR>'
    exe ahead.'ad&just\ end-of-line\ com\.<Tab>'.esc_mapl.'cj              :call SV_AlignLineEndComm()<CR>'
    exe vhead.'ad&just\ end-of-line\ com\.<Tab>'.esc_mapl.'cj              :call SV_AlignLineEndComm()<CR>'
    exe ahead.'&set\ end-of-line\ com\.\ col\.<Tab>'.esc_mapl.'cs     <C-C>:call SV_GetLineEndCommCol()<CR>'
    exe ahead.'-Sep03-                                                     <Nop>'
    exe ahead.'toggle\ &comment<Tab>'.esc_mapl.'cc                         :call SV_CommentToggle()<CR>j'
    exe ihead.'toggle\ &comment<Tab>'.esc_mapl.'cc                    <C-C>:call SV_CommentToggle()<CR>j'
    exe vhead.'toggle\ &comment<Tab>'.esc_mapl.'cc                         :call SV_CommentToggle()<CR>j'

    exe ahead.'comment\ &block<Tab>'.esc_mapl.'cb                          :call SV_CommentBlock("a")<CR>'
    exe ihead.'comment\ &block<Tab>'.esc_mapl.'cb                     <C-C>:call SV_CommentBlock("a")<CR>'
    exe vhead.'comment\ &block<Tab>'.esc_mapl.'cb                     <C-C>:call SV_CommentBlock("v")<CR>'
    exe ahead.'u&ncomment\ block<Tab>'.esc_mapl.'cub                       :call SV_UncommentBlock()<CR>'
    exe ahead.'-Sep01-                                                     <Nop>'
	" sub-menu 'choose styles'
	call mmtemplates#core#CreateMenus ( 'g:SV_Templates', s:SV_RootMenu, 'specials_menu', '&Comments', 'do_styles' )

    "----- Menu : Tools                            {{{2
    "===============================================================================================
	"
	if s:SV_UseToolbox == 'yes' && mmtoolbox#tools#Property ( s:SV_Toolbox, 'empty-menu' ) == 0
		call mmtoolbox#tools#AddMenus ( s:SV_Toolbox, s:SV_RootMenu.'.&Tool\ Box' )
	endif
	"
    return
endfunction    " ----------  end of function s:SV_InitMenus  ----------
"
"===  FUNCTION  ================================================================
"          NAME:  SV_ToolMenu     {{{1
"   DESCRIPTION:  generate the tool menu item
"    PARAMETERS:  -
"       RETURNS:
"===============================================================================
function! SV_ToolMenu ()
    amenu   <silent> 40.1000 &Tools.-SEP100- :
    amenu   <silent> 40.1160 &Tools.Load\ Verilog\ Support :call SV_CreateGuiMenus()<CR>
endfunction    " ----------  end of function SV_ToolMenu  ----------

"===  FUNCTION  ================================================================
"          NAME:  SV_RemoveGuiMenus     {{{1
"   DESCRIPTION:  remove the Verilog menu
"    PARAMETERS:  -
"       RETURNS:
"===============================================================================
function! SV_RemoveGuiMenus ()
  if s:SV_MenuVisible == 'yes'
        exe "aunmenu <silent> ".s:SV_RootMenu
    "
    aunmenu <silent> &Tools.Unload\ Verilog\ Support
        call SV_ToolMenu()
    "
    let s:SV_MenuVisible = 'no'
  endif
endfunction    " ----------  end of function SV_RemoveGuiMenus  ----------

"===  FUNCTION  ================================================================
"          NAME:  SV_RereadTemplates     {{{1
"   DESCRIPTION:  rebuild commands and the menu from the (changed) template file
"    PARAMETERS:  displaymsg - yes / no
"       RETURNS:
"===============================================================================
function! s:SV_RereadTemplates ( displaymsg )
    "
    "-------------------------------------------------------------------------------
    " SETUP TEMPLATE LIBRARY
    "-------------------------------------------------------------------------------
    let g:SV_Templates = mmtemplates#core#NewLibrary ()
    "
    " mapleader
    if empty ( g:SV_MapLeader )
        call mmtemplates#core#Resource ( g:SV_Templates, 'set', 'property', 'Templates::Mapleader', '\' )
    else
        call mmtemplates#core#Resource ( g:SV_Templates, 'set', 'property', 'Templates::Mapleader', g:SV_MapLeader )
    endif
    "
    " map: choose style
    call mmtemplates#core#Resource ( g:SV_Templates, 'set', 'property', 'Templates::ChooseStyle::Map', 'nts' )
    "
    " syntax: comments
    call mmtemplates#core#ChangeSyntax ( g:SV_Templates, 'comment', '§' )
    let s:SV_TemplateJumpTarget = mmtemplates#core#Resource ( g:SV_Templates, "jumptag" )[0]
    "
    let    messsage = ''
    "
    if g:SV_Installation == 'system'
        "-------------------------------------------------------------------------------
        " SYSTEM INSTALLATION
        "-------------------------------------------------------------------------------
        if filereadable( s:SV_GlobalTemplateFile )
            call mmtemplates#core#ReadTemplates ( g:SV_Templates, 'load', s:SV_GlobalTemplateFile )
        else
            echomsg "Global template file '".s:SV_GlobalTemplateFile."' not readable."
            return
        endif
        let    messsage    = "Templates read from '".s:SV_GlobalTemplateFile."'"
        "
        "-------------------------------------------------------------------------------
        " handle local template files
        "-------------------------------------------------------------------------------
        let templ_dir = fnamemodify( s:SV_LocalTemplateFile, ":p:h" ).'/'
        "
        if finddir( templ_dir ) == ''
            " try to create a local template directory
            if exists("*mkdir")
                try
                    call mkdir( templ_dir, "p" )
                catch /.*/
                endtry
            endif
        endif

        if isdirectory( templ_dir ) && !filereadable( s:SV_LocalTemplateFile )
            " write a default local template file
            let template    = [    ]
            let sample_template_file    = g:SV_PluginDir.'/verilog-support/rc/sample_template_file'
            if filereadable( sample_template_file )
                for line in readfile( sample_template_file )
                    call add( template, line )
                endfor
                call writefile( template, s:SV_LocalTemplateFile )
            endif
        endif
        "
        if filereadable( s:SV_LocalTemplateFile )
            call mmtemplates#core#ReadTemplates ( g:SV_Templates, 'load', s:SV_LocalTemplateFile )
            let messsage    = messsage." and '".s:SV_LocalTemplateFile."'"
            if mmtemplates#core#ExpandText( g:SV_Templates, '|AUTHOR|' ) == 'YOUR NAME'
                echomsg "Please set your personal details in file '".s:SV_LocalTemplateFile."'."
            endif
            "
        endif
        "
    else
        "-------------------------------------------------------------------------------
        " LOCAL INSTALLATION
        "-------------------------------------------------------------------------------
        if filereadable( s:SV_LocalTemplateFile )
            call mmtemplates#core#ReadTemplates ( g:SV_Templates, 'load', s:SV_LocalTemplateFile )
            let    messsage    = "Templates read from '".s:SV_LocalTemplateFile."'"
        else
            echomsg "Local template file '".s:SV_LocalTemplateFile."' not readable."
            return
        endif
        "
    endif
    if a:displaymsg == 'yes'
        echomsg messsage.'.'
    endif

endfunction    " ----------  end of function s:SV_RereadTemplates  ----------

"===  FUNCTION  ================================================================
"          NAME:  SV_HighlightJumpTargets     {{{1
"   DESCRIPTION:  highlight the jump targets
"    PARAMETERS:  -
"       RETURNS:
"===============================================================================
function! SV_HighlightJumpTargets ()
	if s:SV_Ctrl_j == 'on'
		exe 'match Search /'.s:SV_TemplateJumpTarget.'/'
	endif
endfunction    " ----------  end of function SV_HighlightJumpTargets  ----------

"===  FUNCTION  ================================================================
"          NAME:  SV_JumpCtrlJ     {{{1
"   DESCRIPTION:  replaces the template system function for C-j
"    PARAMETERS:  -
"       RETURNS:
"===============================================================================
function! SV_JumpCtrlJ ()
  let match	= search( s:SV_TemplateJumpTarget, 'c' )
	if match > 0
		" remove the target
		call setline( match, substitute( getline('.'), s:SV_TemplateJumpTarget, '', '' ) )
	else
		" try to jump behind parenthesis or strings in the current line
		if match( getline(".")[col(".") - 1], "[\]})\"'`]"  ) != 0
			call search( "[\]})\"'`]", '', line(".") )
		endif
		normal! l
	endif
	return ''
endfunction    " ----------  end of function SV_JumpCtrlJ  ----------

"===  FUNCTION  ================================================================
"          NAME:  SV_HelpSupport     {{{1
"   DESCRIPTION:  display plugin help
"    PARAMETERS:  -
"       RETURNS:
"===============================================================================
function! SV_HelpSupport ()
  try
    :help verilog-support
  catch
    exe ':helptags '.g:SV_PluginDir.'/doc'
    :help verilog-support
  endtry
endfunction    " ----------  end of function SV_HelpSupport ----------

"===  FUNCTION  ================================================================
"          NAME:  CreateAdditionalMaps     {{{1
"   DESCRIPTION:  create additional maps
"    PARAMETERS:  -
"       RETURNS:
"===============================================================================
function! s:CreateAdditionalMaps ()
    "
    "-------------------------------------------------------------------------------
    " USER DEFINED COMMANDS
    "-------------------------------------------------------------------------------
    "
    "-------------------------------------------------------------------------------
    " settings - local leader
    "-------------------------------------------------------------------------------
    if ! empty ( g:SV_MapLeader )
        if exists ( 'g:maplocalleader' )
            let ll_save = g:maplocalleader
        endif
        let g:maplocalleader = g:SV_MapLeader
    endif

    " ---------- Key mappings : function keys ------------------------------------
    "
    "   Ctrl-F9   run script
    "    Alt-F9   run syntax check
    "  Shift-F9   set command line arguments
    "  Shift-F1   read Perl documentation
    " Vim (non-GUI) : shifted keys are mapped to their unshifted key !!!
    "
"    if has("gui_running")
"        "
"        noremap    <buffer>  <silent>  <A-F9>             :call SV_SyntaxCheck()<CR>
"        inoremap   <buffer>  <silent>  <A-F9>        <C-C>:call SV_SyntaxCheck()<CR>
"        "
"        noremap    <buffer>  <silent>  <C-F9>             :call SV_Run()<CR>
"        inoremap   <buffer>  <silent>  <C-F9>        <C-C>:call SV_Run()<CR>
"        "
"        noremap    <buffer>            <S-F9>             :PerlScriptArguments<Space>
"        inoremap   <buffer>            <S-F9>        <C-C>:PerlScriptArguments<Space>
"        "
"        noremap    <buffer>  <silent>  <S-F1>             :call SV_perldoc()<CR>
"        inoremap   <buffer>  <silent>  <S-F1>        <C-C>:call SV_perldoc()<CR>
"    endif
    "
    " ---------- plugin help -----------------------------------------------------
    "
    noremap    <buffer>  <silent>  <LocalLeader>hp         :call SV_HelpSupport()<CR>
    inoremap   <buffer>  <silent>  <LocalLeader>hp    <C-C>:call SV_HelpSupport()<CR>
    "
    " ----------------------------------------------------------------------------
    " Comments
    " ----------------------------------------------------------------------------
    "
    noremap     <buffer>  <silent>  <LocalLeader>cl         :call SV_EndOfLineComment()<CR>
    inoremap    <buffer>  <silent>  <LocalLeader>cl    <C-C>:call SV_EndOfLineComment()<CR>
    "
    nnoremap    <buffer>  <silent>  <LocalLeader>cj         :call SV_AlignLineEndComm()<CR>
    inoremap    <buffer>  <silent>  <LocalLeader>cj    <C-C>:call SV_AlignLineEndComm()<CR>
    vnoremap    <buffer>  <silent>  <LocalLeader>cj         :call SV_AlignLineEndComm()<CR>

    nnoremap    <buffer>  <silent>  <LocalLeader>cs         :call SV_GetLineEndCommCol()<CR>

    nnoremap    <buffer>  <silent>  <LocalLeader>cc         :call SV_CommentToggle()<CR>j
    vnoremap    <buffer>  <silent>  <LocalLeader>cc         :call SV_CommentToggle()<CR>j

	nnoremap    <buffer>  <silent>  <LocalLeader>cb         :call SV_CommentBlock("a")<CR>
	inoremap    <buffer>  <silent>  <LocalLeader>cb    <C-C>:call SV_CommentBlock("a")<CR>
	vnoremap    <buffer>  <silent>  <LocalLeader>cb    <C-C>:call SV_CommentBlock("v")<CR>
	nnoremap    <buffer>  <silent>  <LocalLeader>cub        :call SV_UncommentBlock()<CR>
	"
    " ----------------------------------------------------------------------------
    " Snippets & Templates
    " ----------------------------------------------------------------------------
    "
"    nnoremap    <buffer>  <silent>  <LocalLeader>nr         :call SV_CodeSnippet("read")<CR>
"    nnoremap    <buffer>  <silent>  <LocalLeader>nw         :call SV_CodeSnippet("write")<CR>
"    vnoremap    <buffer>  <silent>  <LocalLeader>nw    <Esc>:call SV_CodeSnippet("writemarked")<CR>
"    nnoremap    <buffer>  <silent>  <LocalLeader>ne         :call SV_CodeSnippet("edit")<CR>
"    nnoremap    <buffer>  <silent>  <LocalLeader>nv         :call SV_CodeSnippet("view")<CR>
"    "
"    inoremap    <buffer>  <silent>  <LocalLeader>nr    <Esc>:call SV_CodeSnippet("read")<CR>
"    inoremap    <buffer>  <silent>  <LocalLeader>nw    <Esc>:call SV_CodeSnippet("write")<CR>
"    inoremap    <buffer>  <silent>  <LocalLeader>ne    <Esc>:call SV_CodeSnippet("edit")<CR>
"    inoremap    <buffer>  <silent>  <LocalLeader>nv    <Esc>:call SV_CodeSnippet("view")<CR>

	"-------------------------------------------------------------------------------
	" templates
	"-------------------------------------------------------------------------------

	if !exists("g:SV_Ctrl_j") || ( exists("g:SV_Ctrl_j") && g:SV_Ctrl_j != 'off' )
		nnoremap    <buffer>  <silent>  <C-j>    i<C-R>=SV_JumpCtrlJ()<CR>
		inoremap    <buffer>  <silent>  <C-j>     <C-R>=SV_JumpCtrlJ()<CR>
	endif

	" create the maps for the templates
	" and the 'specials': edit/reload templates, set style, and setup wizard
	call mmtemplates#core#CreateMaps ( 'g:SV_Templates', g:SV_MapLeader, 'do_special_maps' ) |

    "-------------------------------------------------------------------------------
    " tool box
    "-------------------------------------------------------------------------------
    "
    if s:SV_UseToolbox == 'yes'
        call mmtoolbox#tools#AddMaps ( s:SV_Toolbox )
    endif
    "
    "-------------------------------------------------------------------------------
    " settings - reset local leader
    "-------------------------------------------------------------------------------
    if ! empty ( g:SV_MapLeader )
        if exists ( 'll_save' )
            let g:maplocalleader = ll_save
        else
            unlet g:maplocalleader
        endif
    endif
    "
endfunction    " ----------  end of function s:CreateAdditionalMaps  ----------


"===============================================================================
"
" Plug-in setup:  {{{1
"
"------------------------------------------------------------------------------
"  setup the toolbox
"------------------------------------------------------------------------------
"
if s:SV_UseToolbox == 'yes'
    "
    let s:SV_Toolbox = mmtoolbox#tools#NewToolbox ( 'SV' )
    call mmtoolbox#tools#Property ( s:SV_Toolbox, 'mapleader', g:SV_MapLeader )
    "
    call mmtoolbox#tools#Load ( s:SV_Toolbox, s:SV_ToolboxDir )
    "
    " debugging only:
    " call mmtoolbox#tools#Info ( s:SV_Toolbox )
    "
endif
"
call SV_ToolMenu()

if s:SV_LoadMenus == 'yes' && s:SV_CreateMenusDelayed == 'no'
    call SV_CreateGuiMenus()
endif

"------------------------------------------------------------------------------
"  Automated header insertion
"------------------------------------------------------------------------------
if has("autocmd")
    "
    autocmd FileType *
                \    if ( &filetype == 'verilog_systemverilog') |
                \        if ! exists( 'g:SV_Templates' ) |
                \            if s:SV_LoadMenus == 'yes' | call SV_CreateGuiMenus ()        |
                \            else                       | call s:SV_RereadTemplates ('no') |
                \            endif |
                \        endif |
                \        call s:CreateAdditionalMaps() |
                \    endif
    "
    autocmd BufNewFile,BufRead *.sv    setlocal  filetype=verilog_systemverilog
    "
    if s:SV_InsertFileHeader == 'yes'
        autocmd BufNewFile  *.sv,*.svh  call mmtemplates#core#InsertTemplate(g:SV_Templates, 'Comments.Class description')
        autocmd BufNewFile  *.v         call mmtemplates#core#InsertTemplate(g:SV_Templates, 'Comments.Module description')
    endif

    autocmd BufRead  *.sv,*.svh,*.v,*.vh  call SV_HighlightJumpTargets()
    "
    " Wrap error descriptions in the quickfix window.
    autocmd BufReadPost quickfix  setlocal wrap | setlocal linebreak

endif

" }}}1

" vim: tabstop=4 shiftwidth=4 foldmethod=marker
