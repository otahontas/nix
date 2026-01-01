-- Custom filetype definitions, loaded when filetype is on
vim.filetype.add({
  pattern = {
    -- yaml.github-action & yaml.docker-compose needed for proper treesitter, lsp and
    -- formatter setups
    [".*/%.github/actions/.*"] = "yaml.github-action",
    [".*/%.github/workflows/.*"] = "yaml.github-action",
    ["docker%-compose%..*"] = "yaml.docker-compose",
    -- Needed for proper treesitter setup
    ["todo.txt"] = "todotxt",
    -- Bigfile detection
    [".*"] = {
      function(path, buf)
        if not path or not buf or vim.bo[buf].filetype == "bigfile" then
          return
        end
        if path ~= vim.fs.normalize(vim.api.nvim_buf_get_name(buf)) then
          return
        end
        local size = vim.fn.getfsize(path)
        if size <= 0 then
          return
        end
        -- Detect files larger than 1.5MB
        if size > 1.5 * 1024 * 1024 then
          return "bigfile"
        end
        -- Detect minified files with long lines
        local lines = vim.api.nvim_buf_line_count(buf)
        return (size - lines) / lines > 1000 and "bigfile" or nil
      end,
    },
  },
})
