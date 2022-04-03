local home = require('wgc.utils').home

local o = vim.o
local bo = vim.bo
local wo = vim.wo
local opt = vim.opt

o.tabstop = 2
o.softtabstop = 2
o.shiftwidth = 2
o.expandtab = true
o.hidden = true
o.background = 'dark'
o.termguicolors = false
o.syntax = 'on'
o.directory = home()..'/backups/vim/swapfiles//'
o.backupdir = home()..'/backups/vim/backup_files//'
o.undofile = false
o.colorcolumn = '80'
o.completeopt = 'menuone,noinsert,noselect'
o.hlsearch = false

opt.listchars = { tab = '>-', lead = '.', trail = '.' }
opt.path:append {'.','**'}
opt.wildignore:append {'**/debug/**', '**/release/**','**/.git/**'}

bo.autoindent = true
bo.smartindent = true

wo.signcolumn = 'yes'
wo.wrap = false
wo.number = true
wo.relativenumber = true
wo.numberwidth = 3

