require("utils").add_package(
  { {
    src = "https://github.com/nvim-treesitter/nvim-treesitter",
    version = "main",
    data = {
      task = function() vim.cmd("TSUpdate") end,
    },
  },
    {
      src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
      version = "main",
    },
  }, function()
    local treesitter = require("nvim-treesitter")
    local languages = require("languages")

    treesitter.install(languages.treesitters)

    vim.treesitter.language.register("yaml", "yaml.docker-compose")
    vim.treesitter.language.register("yaml", "yaml.github-action")

    vim.api.nvim_create_autocmd("FileType", {
      pattern = languages.filetypes,
      callback = function()
        vim.treesitter.start()
        vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })

    require("nvim-treesitter-textobjects").setup {
      select = {
        lookahead = true,
        selection_modes = {
          ["@parameter.outer"] = "v", -- charwise
          ["@function.outer"] = "V",  -- linewise
          ["@class.outer"] = "<c-v>", -- blockwise
        },
      },
    }

    vim.keymap.set({ "x", "o", }, "af", function()
      require "nvim-treesitter-textobjects.select".select_textobject("@function.outer",
        "textobjects")
    end)
    vim.keymap.set({ "x", "o", }, "if", function()
      require "nvim-treesitter-textobjects.select".select_textobject("@function.inner",
        "textobjects")
    end)
    vim.keymap.set({ "x", "o", }, "ac", function()
      require "nvim-treesitter-textobjects.select".select_textobject("@class.outer",
        "textobjects")
    end)
    vim.keymap.set({ "x", "o", }, "ic", function()
      require "nvim-treesitter-textobjects.select".select_textobject("@class.inner",
        "textobjects")
    end)
    vim.keymap.set({ "x", "o", }, "as", function()
      require "nvim-treesitter-textobjects.select".select_textobject("@local.scope",
        "locals")
    end)
  end)
