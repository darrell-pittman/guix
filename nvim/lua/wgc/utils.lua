local utils = {}

utils.home = (function()
  local home = vim.env.HOME
  return function()
    return home
  end
end)()

utils.make_mapper = function(options)
  return function(mode, lhs, rhs)
    vim.api.nvim_set_keymap(
      mode,
      lhs,
      rhs,
      options
    )
  end
end

utils.make_buf_mapper = function(options)
  return function(bufnr, mode, lhs, rhs)
    vim.api.nvim_buf_set_keymap(
      bufnr,
      mode,
      lhs,
      rhs,
      options
    )
  end
end

return utils
