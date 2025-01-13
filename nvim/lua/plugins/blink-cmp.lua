return {
  'saghen/blink.cmp',
  dependencies = {
    'rafamadriz/friendly-snippets',
    'mikavilpas/blink-ripgrep.nvim',
  },
  version = '0.*',

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer', 'ripgrep' },
      providers = {
        ripgrep = { -- rg suggestions from repo
          module = "blink-ripgrep",
          name = "Ripgrep",
          ---@module "blink-ripgrep"
          ---@type blink-ripgrep.Options
          opts = {
            prefix_min_len = 3,
            context_size = 3,
            max_filesize = "1M",
            project_root_marker = ".git",
            search_casing = "--ignore-case",
            additional_rg_options = {},
            debug = false,
          },
        -- this adds icon next to suggestions
        transform_items = function(_, items)
            for _, item in ipairs(items) do
              item.labelDetails = {
                description = "󰮢",
              }
            end
            return items
          end,
        },
      },
    },
    signature = {
      enabled = true,
      window = { border = "rounded" },
    },
    completion = {
      documentation = {
        auto_show = true,
        window = { border = "single" },
      },
      ghost_text = {
        enabled = true,
      },
    },
  },
  opts_extend = { "sources.default" }
}
