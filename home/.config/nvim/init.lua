-- Neovim config: lazy.nvim + LSP + treesitter + telescope
-- Leader must be set before plugins load
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Options
local o = vim.opt
o.number = true
o.relativenumber = true
o.mouse = "a"
o.ignorecase = true
o.smartcase = true
o.signcolumn = "yes"
o.undofile = true
o.splitright = true
o.splitbelow = true
o.scrolloff = 8
o.updatetime = 250
o.timeoutlen = 400
o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.termguicolors = true
o.cursorline = true
o.inccommand = "split"

-- WSL clipboard (see :h clipboard-wsl)
vim.g.clipboard = {
  name = "WslClipboard",
  copy = {
    ["+"] = "clip.exe",
    ["*"] = "clip.exe",
  },
  paste = {
    ["+"] = 'powershell.exe -NoProfile -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
    ["*"] = 'powershell.exe -NoProfile -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
  },
  cache_enabled = 0,
}
o.clipboard = "unnamedplus"

-- Basic keymaps
local map = vim.keymap.set
map("n", "<Esc>", "<cmd>nohlsearch<CR>")
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostics to loclist" })

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- Theme (matches WezTerm)
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("catppuccin-mocha")
    end,
  },

  -- Syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "vim", "vimdoc", "bash", "json", "yaml", "markdown", "javascript", "typescript", "python", "c_sharp", "html", "css" },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({})
      pcall(telescope.load_extension, "fzf")
      local b = require("telescope.builtin")
      map("n", "<leader>ff", b.find_files, { desc = "Find files" })
      map("n", "<leader>fg", b.live_grep, { desc = "Grep in project" })
      map("n", "<leader>fb", b.buffers, { desc = "Buffers" })
      map("n", "<leader>fh", b.help_tags, { desc = "Help" })
      map("n", "<leader>fr", b.oldfiles, { desc = "Recent files" })
      map("n", "<leader>fd", b.diagnostics, { desc = "Diagnostics" })
    end,
  },

  -- File explorer
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" },
    config = function()
      require("neo-tree").setup({
        filesystem = { follow_current_file = { enabled = true } },
      })
      map("n", "<leader>e", "<cmd>Neotree toggle<CR>", { desc = "File explorer" })
    end,
  },

  -- LSP
  {
    "neovim/nvim-lspconfig", version = "^1",
    dependencies = {
      { "williamboman/mason.nvim", version = "^1" },
      { "williamboman/mason-lspconfig.nvim", version = "^1" },
    },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls" },
        handlers = {
          function(server)
            require("lspconfig")[server].setup({
              capabilities = require("cmp_nvim_lsp").default_capabilities(),
            })
          end,
          lua_ls = function()
            require("lspconfig").lua_ls.setup({
              capabilities = require("cmp_nvim_lsp").default_capabilities(),
              settings = { Lua = { diagnostics = { globals = { "vim" } } } },
            })
          end,
        },
      })
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local opts = { buffer = ev.buf }
          map("n", "gd", vim.lsp.buf.definition, opts)
          map("n", "gr", vim.lsp.buf.references, opts)
          map("n", "gI", vim.lsp.buf.implementation, opts)
          map("n", "K", vim.lsp.buf.hover, opts)
          map("n", "<leader>rn", vim.lsp.buf.rename, opts)
          map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
        end,
      })
    end,
  },

  -- Autocompletion
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      { "L3MON4D3/LuaSnip", dependencies = { "rafamadriz/friendly-snippets" } },
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()
      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then luasnip.jump(-1)
            else fallback() end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
        }, {
          { name = "buffer" },
        }),
      })
    end,
  },

  -- Git signs in the gutter
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
      map("n", "]h", "<cmd>Gitsigns next_hunk<CR>", { desc = "Next git hunk" })
      map("n", "[h", "<cmd>Gitsigns prev_hunk<CR>", { desc = "Previous git hunk" })
      map("n", "<leader>gp", "<cmd>Gitsigns preview_hunk<CR>", { desc = "Preview hunk" })
      map("n", "<leader>gb", "<cmd>Gitsigns blame_line<CR>", { desc = "Blame line" })
    end,
  },

  -- Full diff/PR review view
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("diffview").setup()
      map("n", "<leader>gd", "<cmd>DiffviewOpen<CR>", { desc = "Open diff view" })
      map("n", "<leader>gh", "<cmd>DiffviewFileHistory<CR>", { desc = "File history (all)" })
      map("n", "<leader>gH", "<cmd>DiffviewFileHistory %<CR>", { desc = "File history (current file)" })
      map("n", "<leader>gq", "<cmd>DiffviewClose<CR>", { desc = "Close diff view" })
    end,
  },

  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = { options = { theme = "auto" } },
  },

  -- Keybinding hints popup
  { "folke/which-key.nvim", event = "VeryLazy", opts = {} },

  -- Auto-close brackets/quotes
  { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },

  -- Indentation guides
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },

  -- Surround motions (ys, cs, ds)
  { "kylechui/nvim-surround", event = "VeryLazy", opts = {} },
})
