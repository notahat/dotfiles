-- Install language servers and formatters.
--
-- Mason puts them in ~/.local/share/NVIM_APPNAME/mason
return {
  "mason-org/mason.nvim",
  opts = {
    PATH = "append",
  },
}
