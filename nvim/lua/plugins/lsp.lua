return {
  'neovim/nvim-lspconfig',
  dependencies = {
    { 'williamboman/mason.nvim', config = true },
    { 'williamboman/mason-lspconfig.nvim' },
    { 'WhoIsSethDaniel/mason-tool-installer.nvim' },
    { 'saghen/blink.cmp' },
  },
  config = function()
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
      callback = function(event)
        vim.keymap.set('n',          'gd',         require('telescope.builtin').lsp_definitions,               { desc = 'LSP: [G]oto [D]efinition' })
        vim.keymap.set('n',          'gr',         require('telescope.builtin').lsp_references,                { desc = 'LSP: [G]oto [R]eferences' })
        vim.keymap.set('n',          'gI',         require('telescope.builtin').lsp_implementations,           { desc = 'LSP: [G]oto [I]mplementation' })
        vim.keymap.set('n',          '<leader>D',  require('telescope.builtin').lsp_type_definitions,          { desc = 'LSP: Type [D]efinition' })
        vim.keymap.set('n',          '<leader>ds', require('telescope.builtin').lsp_document_symbols,          { desc = 'LSP: [D]ocument [S]ymbols' })
        vim.keymap.set('n',          '<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, { desc = 'LSP: [W]orkspace [S]ymbols' })
        vim.keymap.set('n',          '<leader>rn', vim.lsp.buf.rename,                                         { desc = 'LSP: [R]e[n]ame' })
        vim.keymap.set('n',          'gD',         vim.lsp.buf.declaration,                                    { desc = 'LSP: [G]oto [D]eclaration' })
        vim.keymap.set({ 'n', 'x' }, '<leader>ca', vim.lsp.buf.code_action,                                    { desc = 'LSP: [C]ode [A]ction' })
        vim.keymap.set('n',          '<leader>th',  function() -- inlay hints can move your code
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = vim.api.nvim_get_current_buf() })
        end,
        { desc = 'LSP: [T]oggle Inlay [H]ints' })
        -- highlight word
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
          local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
            end,
          })
        end
      end,
    })
    -- settings for LSPs go here
    local servers = {
      -- See `:help lspconfig-all` for a list of all the pre-configured LSPs
      gopls = {},
      -- pyright = {},
      ruff = {
        -- Notes on code actions: https://github.com/astral-sh/ruff-lsp/issues/119#issuecomment-1595628355
        -- Get isort like behavior: https://github.com/astral-sh/ruff/issues/8926#issuecomment-1834048218
        commands = {
          RuffAutofix = {
            function()
              vim.lsp.buf.execute_command {
                command = 'ruff.applyAutofix',
                arguments = {
                  { uri = vim.uri_from_bufnr(0) },
                },
              }
            end,
            description = 'Ruff: Fix all auto-fixable problems',
          },
          RuffOrganizeImports = {
            function()
              vim.lsp.buf.execute_command {
                command = 'ruff.applyOrganizeImports',
                arguments = {
                  { uri = vim.uri_from_bufnr(0) },
                },
              }
            end,
            description = 'Ruff: Format imports',
          },
        },
      },
      rust_analyzer = {
        ['rust-analyzer'] = {
          cargo = {
            features = 'all',
          },
          checkOnSave = true,
          check = {
            command = 'clippy',
          },
        },
      },
      pylsp = {
        settings = {
          pylsp = {
            plugins = { -- let ruff handle these
              pyflakes = { enabled = false },
              pycodestyle = { enabled = false },
              autopep8 = { enabled = false },
              yapf = { enabled = false },
              mccabe = { enabled = false },
              pylsp_mypy = { enabled = false },
              pylsp_black = { enabled = false },
              pylsp_isort = { enabled = false },
            },
          },
        },
      },
      dockerls = {},
      terraformls = {},
      jsonls = {},
      yamlls = {},
      lua_ls = {
        settings = {
          Lua = {
            completion = {
              callSnippet = 'Replace',
            },
            runtime = { version = 'LuaJIT' },
            workspace = {
              checkThirdParty = false,
              library = { vim.env.VIMRUNTIME },
            },
            diagnostics = { disable = { 'missing-fields' } },
            format = {
              enable = false,
            },
          },
        },
      },
    }

    -- Set up Mason-LSPConfig
    require('mason-lspconfig').setup {
      handlers = {
        function(server_name)
          local lsp_config = require('lspconfig')
          local server = servers[server_name] or {}
          -- Merge Blink capabilities with any existing ones
          server.capabilities = require('blink.cmp').get_lsp_capabilities(server.capabilities or {})
          -- Setup the server
          lsp_config[server_name].setup(server)
        end,
      },
    }
  end,
}
