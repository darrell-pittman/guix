
" An example for a vimrc file.
"
" Maintainer:	Bram Moolenaar <Bram@vim.org>
" Last change:	2019 Dec 17
"
" To use it, copy it to
"	       for Unix:  ~/.vimrc
"	      for Amiga:  s:.vimrc
"	 for MS-Windows:  $VIM\_vimrc
"	      for Haiku:  ~/config/settings/vim/vimrc
"	    for OpenVMS:  sys$login:.vimrc

" When started as "evim", evim.vim will already have done these settings, bail
" out.
if v:progname =~? "evim"
  finish
endif

" Get the defaults that most users want.
source $VIMRUNTIME/defaults.vim

if has("vms")
  set nobackup		" do not keep a backup file, use versions instead
else
  set backup		" keep a backup file (restore to previous version)
  if has('persistent_undo')
    set undofile	" keep an undo file (undo changes after closing)
  endif
endif

if &t_Co > 2 || has("gui_running")
  " Switch on highlighting the last used search pattern.
  set hlsearch
endif

" Put these in an autocmd group, so that we can delete them easily.
augroup vimrcEx
  au!

  " For all text files set 'textwidth' to 78 characters.
  autocmd FileType text setlocal textwidth=78
augroup END

" Add optional packages.
"
" The matchit plugin makes the % command work better, but it is not backwards
" compatible.
" The ! means the package won't be loaded right away but when plugins are
" loaded during initialization.
if has('syntax') && has('eval')
  packadd! matchit
endif



"----------------------------------------------------------Plugins
call plug#begin('~/.vim/plugged')

Plug 'prabirshrestha/vim-lsp'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'

call plug#end()
	

"----------------------------------------------------------LSP
if executable('rust-analyzer')
	au User lsp_setup call lsp#register_server({
	\   'name': 'Rust Language Server',
	\   'cmd': {server_info->['rust-analyzer']},
	\   'whitelist': ['rust'],
	\ })
endif

function! s:on_lsp_buffer_enabled() abort
  setlocal omnifunc=lsp#complete
  setlocal signcolumn=yes
  if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif
  nmap <buffer> gd <plug>(lsp-definition)
  nmap <buffer> gs <plug>(lsp-document-symbol-search)
  nmap <buffer> gS <plug>(lsp-workspace-symbol-search)
  nmap <buffer> gr <plug>(lsp-references)
  nmap <buffer> gi <plug>(lsp-implementation)
  nmap <buffer> gt <plug>(lsp-type-definition)
  nmap <buffer> <leader>rn <plug>(lsp-rename)
  nmap <buffer> [g <plug>(lsp-previous-diagnostic)
  nmap <buffer> ]g <plug>(lsp-next-diagnostic)
  nmap <buffer> K <plug>(lsp-hover)
  nnoremap <buffer> <expr><c-f> lsp#scroll(+4)
  nnoremap <buffer> <expr><c-d> lsp#scroll(-4)

  let g:lsp_format_sync_timeout = 1000
  autocmd! BufWritePre *.rs,*.go call execute('LspDocumentFormatSync')

  " refer to doc to add more commands
endfunction

augroup lsp_install
  au!
    " call s:on_lsp_buffer_enabled only for languages that has the server registered.
    autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END



inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <cr>    pumvisible() ? asyncomplete#close_popup() : "\<cr>"
imap <c-@> <Plug>(asyncomplete_force_refresh)

"----------------------------------------------------------Options
set hidden
set nowrap
set relativenumber
set directory=$HOME/.vim/swap_files//
set backupdir=$HOME/.vim/backup_files//
set undodir=$HOME/.vim/undo_files//

"----------------------------------------------------------Ctrl-P
" Load Ctrl-P
set runtimepath^=$HOME/.vim/bundle/ctrlp.vim

" Setup ignores for Ctrl-P
set wildignore+=*/.git
let g:ctrlp_custom_ignore = {
			\ 'dir': '\v[\/]target$',
			\ 'file': '\v[\/]target\/.*$',
			\ }

"----------------------------------------------------------Look and Feel
set background=dark
highlight LineNr ctermbg=238 ctermfg=253
highlight Search ctermbg=088 ctermfg=206
highlight CursorLine cterm=NONE ctermbg=237 ctermfg=NONE
highlight CursorLineNr cterm=NONE ctermbg=232 ctermfg=015
set cursorline
set numberwidth=3

"----------------------------------------------------------Key Mappings
let mapleader = ","
let maplocalleader = "'"
inoremap jk <Esc>
nnoremap <leader>u :execute "normal! mqviwU`q" <bar> delmark q<cr>
nnoremap <leader>ev :vsplit $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>

"----------------------------------------------------------Rust
cabbrev ct !cargo test --lib

