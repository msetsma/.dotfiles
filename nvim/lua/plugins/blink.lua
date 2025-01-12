return {
  'saghen/blink.cmp',
  -- optional: provides snippets for the snippet source
  dependencies = {
    'rafamadriz/friendly-snippets',
    'mikavilpas/blink-ripgrep.nvim',
  },
  version = '0.*',

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = { preset = 'default' },
    appearance = {
      nerd_font_variant = 'mono'
    },

    sources = {
      default = { "lazydev", 'lsp', 'path', 'snippets', 'buffer', 'ripgrep' },
      providers = {
        lazydev = {
          name = "LazyDev",
          module = "lazydev.integrations.blink",
          score_offset = 100,
        },
        ripgrep = {
          module = "blink-ripgrep",
          name = "Ripgrep",
          ---@module "blink-ripgrep"
          ---@type blink-ripgrep.Options
          opts = {
            prefix_min_len = 3,
            context_size = 5,
            max_filesize = "1M",
            project_root_marker = ".git",
            search_casing = "--ignore-case",
            additional_rg_options = {},
            debug = false,
          },
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
  },
  opts_extend = { "sources.default" }
}
