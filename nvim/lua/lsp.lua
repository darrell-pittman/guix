local utils = require('wgc.utils')

local silent_mapper = utils.make_mapper { silent = true} 
local silent_buf_mapper = utils.make_mapper { buffer = true, silent = true} 

-- LSP
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
silent_mapper('n', '<leader>e', '<cmd>lua vim.diagnostic.open_float()<CR>')
silent_mapper('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>')
silent_mapper('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>')
silent_mapper('n', '<leader>q', '<cmd>lua vim.diagnostic.setloclist()<CR>')

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  silent_buf_mapper(bufnr, 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>')
  silent_buf_mapper(bufnr, 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
  silent_buf_mapper(bufnr, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')
  silent_buf_mapper(bufnr, 'n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>')
  silent_buf_mapper(bufnr, 'n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>')
  silent_buf_mapper(bufnr, 'n', '<leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>')
  silent_buf_mapper(bufnr, 'n', '<leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>')
  silent_buf_mapper(bufnr, 'n', '<leader>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>')
  silent_buf_mapper(bufnr, 'n', '<leader>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>')
  silent_buf_mapper(bufnr, 'n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>')
  silent_buf_mapper(bufnr, 'n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>')
  silent_buf_mapper(bufnr, 'n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>')
  silent_buf_mapper(bufnr, 'n', '<leader>t', '<cmd>lua vim.lsp.buf.formatting()<CR>')
end

-- Use a loop to conveniently call 'setup' on multiple servers and

-- map buffer local keybindings when the language server attaches
local servers = { 'rust_analyzer' }
for _, lsp in pairs(servers) do
  require('lspconfig')[lsp].setup {
    on_attach = on_attach,
    flags = {
      -- This will be the default in neovim 0.7+
      debounce_text_changes = 150,
    }
  }
end
