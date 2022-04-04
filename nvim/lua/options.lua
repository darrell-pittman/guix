local home = require('wgc.utils').home

local set = vim.opt

set.tabstop = 2
set.softtabstop = 2
set.shiftwidth = 2
set.expandtab = true
set.hidden = true
set.background = 'dark'
set.termguicolors = false
set.syntax = 'on'
set.directory = home()..'/backups/vim/swapfiles//'
set.backupdir = home()..'/backups/vim/backup_files//'
set.undofile = false
set.colorcolumn = '80'
set.completeopt = 'menuone,noinsert,noselect'
set.hlsearch = false

set.listchars = { tab = '>-', lead = '.', trail = '.' }
set.path:append {'.','**'}
set.wildignore:append {'**/debug/**', '**/release/**','**/.git/**'}

set.autoindent = true
set.smartindent = true
set.signcolumn = 'yes'
set.wrap = false
set.number = true
set.relativenumber = true
set.numberwidth = 3

