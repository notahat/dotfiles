local function copy_relative_path()
    local path = vim.fn.expand("%:.")
    vim.fn.setreg("+", path)
    vim.notify("Path copied: " .. path)
end

local function configure()
    vim.cmd.packadd({ "lualine.nvim", bang = true }) -- https://github.com/nvim-lualine/lualine.nvim
    local lualine = require("lualine")
    lualine.setup({
        options = { theme = "auto" },
        sections = {
            lualine_c = { { "filename", path = 1, on_click = copy_relative_path } },
        },
    })

    vim.o.showmode = false -- Lualine shows the mode for us.
    vim.o.laststatus = 3 -- Use a full-width status line.
end

return { configure = configure }
