-- Map the leader key
vim.api.nvim_set_keymap('n','<Space>', '',{})
vim.g.mapleader = ' '
vim.g.maplocalleader = "'"

local utils = require('wgc.utils')

local silent_mapper = utils.make_mapper { noremap = true, silent = true} 
local mapper = utils.make_mapper { noremap = true }

-- Use jk for escape in insert mode 
silent_mapper('i','jk','<Esc>')

-- <leader>u to uppercase word
silent_mapper('n', '<leader>u', 'gUiw')

silent_mapper('i', '<leader><tab>', '<C-x><C-o>')

mapper('n', '<leader>f', ':find<space>')

-- Turn off arrow keys
silent_mapper('', '<left>','')
silent_mapper('', '<right>','')
silent_mapper('', '<up>','')
silent_mapper('', '<down>','')
silent_mapper('i', '<left>','')
silent_mapper('i', '<right>','')
silent_mapper('i', '<up>','')
silent_mapper('i', '<down>','')

