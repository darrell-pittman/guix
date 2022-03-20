if v:progname =~? "evim"
    finish
endif

" Get the defaults that most users want.
source $VIMRUNTIME/defaults.vim

if has("vms")
    set nobackup		" do not keep a backup file, use versions instead
else
    set backup		" keep a backup file (restore to previous version)
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
Plug 'tpope/vim-fugitive'

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
    nmap <buffer> <leader>lr <plug>(lsp-rename)
    nmap <buffer> [g <plug>(lsp-previous-diagnostic)
    nmap <buffer> ]g <plug>(lsp-next-diagnostic)
    nmap <buffer> K <plug>(lsp-hover)
    nnoremap <buffer> <expr><c-f> lsp#scroll(+4)
    nnoremap <buffer> <expr><c-d> lsp#scroll(-4)
    nnoremap <buffer> <leader>le :LspDocumentDiagnostics<cr>
    nnoremap <buffer> <leader>la :LspCodeAction<cr>

    let g:lsp_format_sync_timeout = 1000
    autocmd! BufWritePre *.rs,*.go call execute('LspDocumentFormatSync')

    highlight LspWarningHighlight cterm=underline
    highlight LspErrorHighlight cterm=underline
    highlight LspReference cterm=NONE

    let g:asyncomplete_auto_popup = 0

    function! s:check_back_space() abort
        let col = col('.') - 1
        return !col || getline('.')[col - 1]  =~ '\s'
    endfunction

    inoremap <silent><expr> <TAB>
                \ pumvisible() ? "\<C-n>" :
                \ <SID>check_back_space() ? "\<TAB>" :
                \ asyncomplete#force_refresh()
    inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

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
set number

set directory=$HOME/backups/vim/swap_files//
set backupdir=$HOME/backups/vim/backup_files//
set undodir=$HOME/backups/vim/undo_files//
set tabstop=4 softtabstop=4 shiftwidth=4 expandtab
set path+=.,**
set wildignore+=**/debug/**
set wildignore+=**/release/**
set wildignore+=**/.git/**

"----------------------------------------------------------Ctrl-P
" Load Ctrl-P
"set runtimepath^=$HOME/.vim/bundle/ctrlp.vim
"
"" Setup ignores for Ctrl-P
"set wildignore+=*/.git
"let g:ctrlp_custom_ignore = {
"            \ 'dir': '\v[\/]target$',
"            \ 'file': '\v[\/]target\/.*$',
"            \ }
"let g:ctrlp_map = '<leader>f'

"----------------------------------------------------------Look and Feel
set background=dark
set numberwidth=3
colorscheme murphy

"----------------------------------------------------------Key Mappings
let mapleader = ","
let maplocalleader = "'"
inoremap jk <Esc>
nnoremap <leader>u gUiw
nnoremap <leader>ev :vsplit $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>
nnoremap <leader>g :Git<cr>
nnoremap <leader>f :find<space>

"Turn off arrow keys
noremap <left> <Nop>
noremap <right> <Nop>
noremap <up> <Nop>
noremap <down> <Nop>
inoremap <left> <Nop>
inoremap <right> <Nop>
inoremap <up> <Nop>
inoremap <down> <Nop>


"----------------------------------------------------------Rust
augroup rust_group
    autocmd!
    autocmd FileType rust cabbrev ct !cargo test --lib
    autocmd FileType rust cabbrev cr !cargo run --release --bin
    autocmd FileType rust nnoremap <buffer> <leader>bk :!cargo check<cr>
    autocmd FileType rust nnoremap <buffer> <leader>bc :!cargo build<cr>
    autocmd FileType rust nnoremap <buffer> <leader>bcr :!cargo build --release<cr>
    autocmd FileType vim setlocal tabstop=4 softtabstop=4 shiftwidth=4 expandtab
augroup END

"----------------------------------------------------------Vim
augroup vim_group
    autocmd!
    autocmd FileType vim setlocal tabstop=4 softtabstop=4 shiftwidth=4 expandtab
augroup END

