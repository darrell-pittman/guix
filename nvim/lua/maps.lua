-- Map the leader key
vim.api.nvim_set_keymap('n','<Space>', '',{})
vim.g.mapleader = ' '
vim.g.maplocalleader = "'"

local utils = require('wgc.utils')
local t = utils.t

local silent_mapper = utils.make_mapper { silent = true} 
local mapper = utils.make_mapper()
local expr_mapper =  utils.make_mapper { expr =  true }

-- Use jk for escape in insert mode 
silent_mapper('i','jk','<Esc>')

-- <leader>u to uppercase word
silent_mapper('n', '<leader>u', 'gUiw')

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

-- Completion

_G.wgc_smart_tab = function ()
  if vim.fn.pumvisible() == 1 then
    return t'<C-n>'
  else
    local col = vim.fn.col('.') - 1
    local backspace = (col == 0) or (vim.fn.getline('.'):sub(col,col):match('%s'))
    if backspace then
      return t'<Tab>'
    else
      return t'<C-x><C-o>'
    end
  end
end

local completion_mapper = utils.make_mapper { expr =  true }
completion_mapper('i', '<Tab>', 'v:lua.wgc_smart_tab()')


vim.cmd[[
map <F4> :execute "vimgrep /" . expand("<cword>") . "/j **" <Bar> cw<CR>
]]
