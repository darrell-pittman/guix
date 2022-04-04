local utils = {}

utils.home = (function()
  local home = vim.env.HOME
  return function()
    return home
  end
end)()

utils.t = function(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

utils.make_mapper = function(key)
  local options = { noremap = true }

  if key then
    for i,v in pairs(key) do
      if type(i) == 'string' then options[i] = v end
    end
  end

  local buffer = options.buffer
  options.buffer = nil

  if buffer then
    return function(bufnr, mode, lhs, rhs)
      vim.api.nvim_buf_set_keymap(
      bufnr,
      mode,
      lhs,
      rhs,
      options
      )
    end
  else
    return function(mode, lhs, rhs)
      vim.api.nvim_set_keymap(
      mode,
      lhs,
      rhs,
      options
      )
    end
  end
end

return utils
