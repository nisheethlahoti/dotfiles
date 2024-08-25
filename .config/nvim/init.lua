local vim = vim
local autocmd = vim.api.nvim_create_autocmd
local command = vim.api.nvim_create_user_command
local keymap = vim.keymap.set
local highlight = vim.api.nvim_set_hl

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath('data')..'/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.system {'git', 'clone', 'https://github.com/folke/lazy.nvim', '-b', 'stable', lazypath}
end
vim.opt.rtp:prepend(lazypath)

-- Basics
vim.o.breakindent = true                     -- Wrapped part of any line also appears indented
vim.o.linebreak = true                       -- When wrapping text, break on word boundaries
vim.o.tabstop = 4                            -- No. of spaces that a <Tab> in the file counts for
vim.o.shiftwidth = 4                         -- No. of spaces to use for each step of (auto)indent
vim.o.inccommand = 'split'                   -- Show effects of a command incrementally as you type
vim.o.undofile = true                        -- Keep an undo file (undo changes after closing)
vim.o.number = true                          -- Display every line's number
vim.o.lazyredraw = true                      -- Don't draw while executing macros, speeding them up
vim.o.mouse = 'a'                            -- Enable use of the mouse like a normal application
vim.o.wrap = false                           -- Disable word wrap
vim.o.scrolloff = 5                          -- Min number of screen lines to keep around the cursor
vim.o.sidescroll = 5                         -- Min number of characters to keep on screen
vim.opt.lcs:append('extends:>')              -- Show marker if line extends beyond screen
vim.opt.matchpairs:append('<:>')             -- Use '%' to navigate between '<' and '>'
vim.o.foldenable = false                     -- Folds off by default
vim.o.foldmethod = 'expr'                    -- Fold according to given expression (treesitter)
vim.o.foldexpr = 'nvim_treesitter#foldexpr()'
vim.o.foldtext = 'gitgutter#fold#foldtext()' -- Show if folded lines have changed
vim.opt.clipboard:append('unnamedplus')      -- Use clipboard by default for yank/delete/paste
vim.opt.display:append('uhex')               -- Show hex for unprintable characters
vim.o.diffopt = vim.o.diffopt..',vertical,algorithm:histogram,indent-heuristic'

-- Set clipboard to OSC52 in case of ssh (copy into clipboard from remote locations)
if os.getenv('SSH_TTY') then
  local function paste() return {vim.split(vim.fn.getreg(''), '\n'), vim.fn.getregtype('')} end
  vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
      ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
      ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
    },
    paste = {['+'] = paste, ['*'] = paste},
  }
end

vim.g.mapleader = ' '
if vim.fn.isdirectory(os.getenv('HOME')..'/micromamba') then
  vim.g.python3_host_prog = os.getenv('HOME')..'/micromamba/bin/python'
end

-- Moving between windows
for key in vim.iter({'h', 'j', 'k', 'l'}) do
  keymap('t', '<C-'..key..'>', '<C-\\><C-n><C-w>'..key) -- in terminal mode
  keymap('', '<C-'..key..'>', '<C-w>'..key)             -- in n/v/o modes
end

-- For tmux-like zooming
keymap('', '<Leader>t', ':tab split<CR>')
keymap('', '<Leader>T', ':tabclose<CR>')

-- Replacing shortcuts, plus use very-magic for regexes
keymap('', '/', '/\\v')
keymap('', '?', '?\\v')
keymap('', '<Leader>s', ':s/\\v')
keymap('', '<Leader>S', ':%s/\\v')

-- For clearing out last search highlight
keymap('n', '<Esc>', vim.cmd.noh, {silent = true})

-- Commands to change directory to current file's and back to global
keymap('n', '<Leader>cd', ':lcd %:p:h | pwd<CR>', {silent = true})
keymap('n', '<Leader>cD', ':exe "lcd" getcwd(-1, -1) | pwd<CR>', {silent = true})

-- Delete buffer without destroying window layout
command('Bdelete', 'bp | bd<bang>#', {bang = true})

-- Commands to do the intended thing on overly common typos
command('W', 'w', {})
command('Q', 'q<bang>', {bang = true})
command('Wq', 'wq', {})
command('Qa', 'qa<bang>', {bang = true})

-- Commands for editing, help, and terminal in new vertical window
command('E', 'vert new <args>', {nargs = '?', complete = 'file'})
command('Term', 'vsplit | term', {})

-- Help and man in floating windows (supporting keywordprg)
local function FloatingExec(cmdtext)
  return function(cmd)
    vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), true, {
      relative = 'editor',
      row = math.floor(0.1 * vim.o.lines),
      col = math.floor(0.1 * vim.o.columns),
      height = math.floor(0.8 * vim.o.lines),
      width = math.floor(0.8 * vim.o.columns),
      border = 'single',
    })

    xpcall(function()
      vim.api.nvim_exec2(cmdtext..' '..cmd.args, {})
      keymap('n', '<Esc>', vim.cmd.q, {buffer = true, silent = true})
    end, function(err)
      vim.api.nvim_err_writeln(err)
      vim.cmd.quit()
    end)
  end
end

command('Help', FloatingExec('set buftype=help | help'), {nargs = '?', complete = 'help'})
command('FloatMan', FloatingExec('Man! | Man'), {nargs = 1})
local keywordmap = {[':help'] = ':Help', [':Man'] = ':FloatMan'}
autocmd('BufEnter', {
  callback = function(_) vim.o.keywordprg = keywordmap[vim.o.keywordprg] or vim.o.keywordprg end,
})

-- Convert binary file to readable bytes output and vice-versa
keymap('', '<Leader>x', function()
  vim.bo.binary = not vim.bo.binary
  vim.cmd('%!xxd'..(vim.bo.binary and ' -r' or ''))
end)

-- Set wrap only for certain file types
local wrap_ft = {'text', 'markdown'}
autocmd('FileType', {callback = function(e) vim.wo.wrap = vim.list_contains(wrap_ft, e.match) end})

-- Setup plugins
require('lazy').setup {
  -- Editing motions
  'tpope/vim-surround',           -- Surround with parentheses/HTML-tags etc.
  'tpope/vim-repeat',             -- Use '.' with several plugins
  'jeetsukumaran/vim-indentwise', -- Motions over indented blocks

  -- General
  'tpope/vim-vinegar',           -- Browsing files
  {
    'nvim-lualine/lualine.nvim', -- Better status line
    opts = {options = {theme = 'nord'}, sections = {lualine_y = {'%B'}}},
  },
  {
    'junegunn/fzf.vim', -- Vim bindings for fzf
    dependencies = {{'junegunn/fzf', build = './install --all'}},
    config = function()
      vim.g.fzf_layout = {window = {width = 0.8, height = 0.8, relative = 'editor'}}
      keymap('', '<Leader>o', ':Files<CR>')
      keymap('', '<Leader>l', ':Rg<CR>')
      keymap('', '<Leader>h', ':History:<CR>')
    end,
  },
  'tpope/vim-fugitive',        -- Git usage integration
  {
    'lewis6991/gitsigns.nvim', -- hunk object and signs for changed lines
    opts = {
      on_attach = function(bufnr)
        local opts = {buffer = bufnr, silent = true}
        local gitsigns = require('gitsigns')
        keymap({'o', 'x'}, 'ih', gitsigns.select_hunk, opts)  -- Text object

        for dest, key in pairs({next = ']c', prev = '[c'}) do -- Navigation
          keymap('', key, function()
            if vim.wo.diff then vim.cmd.normal({key, bang = true}) else gitsigns.nav_hunk(dest) end
          end, opts)
        end
      end,
    },
  },
  {
    'rmagatti/auto-session',               -- Remote persistence for neovim
    enabled = os.getenv('SSH_TTY') ~= nil, -- Only use in SSH environments
    opts = {log_level = 'error'},
  },
  {
    'hrsh7th/nvim-cmp', -- Autocomplete
    dependencies = {'hrsh7th/cmp-buffer', 'hrsh7th/cmp-path'},
    opts = function()
      local cmp = require('cmp')
      return {
        mapping = cmp.mapping.preset.insert({
          ['<C-Space>'] = cmp.mapping.confirm(),
          ['<Tab>'] = cmp.mapping.select_next_item(),
          ['<S-Tab>'] = cmp.mapping.select_prev_item(),
        }),
        sources = cmp.config.sources({{name = 'nvim_lsp'}}, {{name = 'buffer'}}, {{name = 'path'}}),
      }
    end,
  },
  {
    'hrsh7th/cmp-cmdline', -- Autocomplete for command line
    dependencies = {'hrsh7th/nvim-cmp', 'hrsh7th/cmp-buffer', 'hrsh7th/cmp-path'},
    config = function()
      local cmp = require('cmp')

      cmp.setup.cmdline({'/', '?'}, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {{name = 'buffer'}},
      })

      cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({{name = 'path'}}, {{name = 'cmdline'}}),
      })
    end,
  },

  -- Language awareness
  {
    'nvim-treesitter/nvim-treesitter', -- Language syntax parsing
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs',
    opts = {
      ensure_installed = {'bash', 'cpp', 'lua', 'python', 'rust', 'vim', 'vimdoc'},
      auto_install = true, -- On entering new buffer, install its parser if available
      highlight = {enable = true, additional_vim_regex_highlighting = false},
      incremental_selection = {
        enable = true,
        keymaps = {node_incremental = '/', node_decremental = '?'},
      },
    },
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects', -- Text-objects based on treesitter
    dependencies = {'nvim-treesitter/nvim-treesitter'},
    main = 'nvim-treesitter.configs',
    opts = function(_, opts)
      opts.textobjects = {
        select = {
          enable = true,
          keymaps = {
            af = '@function.outer',
            ['if'] = '@function.inner',
            ac = '@class.outer',
            ic = '@class.inner',
            ab = '@block.outer',
            ib = '@block.inner',
            au = '@call.outer',
            iu = '@call.inner',
          },
        },
        lsp_interop = {
          enable = true,
          border = 'single',
          peek_definition_code = {
            ['<Leader>df'] = '@function.outer', ['<Leader>dF'] = '@class.outer',
          },
        },
      }
    end,
  },
  {
    'mfussenegger/nvim-dap', -- Debug adapter protocol
    config = function()
      local dap = require('dap')
      dap.adapters.python = {
        type = 'executable',
        command = vim.g.python3_host_prog,
        args = {'-m', 'debugpy.adapter'},
      }
      dap.configurations.python = {{
        -- nvim-dap options
        type = 'python', -- this links to the adapter definition: `dap.adapters.python`
        request = 'launch',
        name = 'Launch file',
        justMyCode = false,  -- Allow debugging inside libraries as well
        -- debugpy options, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings
        program = '${file}', -- This configuration will launch the current file if used.
        args = function()
          local infile = vim.fn.input('Arguments file: ')
          return infile == '' and {} or vim.fn.readfile(infile)
        end,
        pythonPath = function() return vim.fn.system('which python3'):sub(1, -2) end,
      }}
      local dapmap = {
        c = dap.continue,
        n = dap.step_over,
        s = dap.step_into,
        r = dap.step_out,
        b = dap.toggle_breakpoint,
        R = dap.repl.open,
        l = dap.list_breakpoints, -- Populate quickfix list with breakpoints
        B = function() vim.ui.input('Breakpoint condition: ', dap.set_breakpoint) end,
        q = dap.terminate,
      }
      for key, val in pairs(dapmap) do keymap('', '<BS>'..key, val) end
    end,
  },
  {
    'rcarriga/nvim-dap-ui', -- Frontend for nvim-dap
    dependencies = {'mfussenegger/nvim-dap', 'nvim-neotest/nvim-nio'},
    config = function()
      local dap = require('dap')
      local dapui = require('dapui')
      dapui.setup()
      keymap('', '<BS>w', dapui.toggle)
      dap.listeners.before.attach.dapui_config = dapui.open
      dap.listeners.before.launch.dapui_config = dapui.open
      dap.listeners.before.event_terminated.dapui_config = dapui.close
    end,
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = {'hrsh7th/cmp-nvim-lsp'},
    config = function()
      local lspc = require('lspconfig')
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      local function lsp_set(name, settings)
        lspc[name].setup(vim.tbl_deep_extend('keep', settings or {}, {capabilities = capabilities}))
      end
      lsp_set('rust_analyzer', {cmd = {'rustup', 'run', 'nightly', 'rust-analyzer'}})
      lsp_set('clangd', {cmd = {'clangd', '--clang-tidy', '--header-insertion=never'}})
      lsp_set('pyright')
      lsp_set('ruff')
      lsp_set('lua_ls')
      lsp_set('jsonls')
    end,
    -- TODO(neovim/16807): Set logfile path in temp, and possibly improve format
  },
}

-- Keybindings and default changes on attaching LSP
autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    -- Server-specific: disable ruff's hover in favor of pyright
    if client.name == 'ruff' then client.server_capabilities.hoverProvider = false end

    local function lspmap(mode, key, method, cmd)
      if client.supports_method('textDocument/'..method) then
        keymap(mode, key, cmd, {silent = true, buffer = args.buf})
      end
    end

    local function map_to(key, method, cmd) lspmap('', '<Leader><Leader>'..key, method, cmd) end

    map_to('f', 'formatting', function()
      -- TODO(neovim/neovim/24168): Replace below with 2 lines using vim.lsp.buf.code_action
      for _, action in ipairs({'source.fixAll', 'source.organizeImports'}) do
        local params = vim.lsp.util.make_range_params()
        params.context = {only = {action}, diagnostics = {}}
        local result = client.request_sync('textDocument/codeAction', params, 1000, args.buf)
        for _, r in ipairs(result.result or {}) do
          if not (r.command or r.edit) then
            r = client.request_sync('codeAction/resolve', r, 1000, args.buf).result
          end
          if r.edit then
            vim.lsp.util.apply_workspace_edit(r.edit, client.offset_encoding)
          elseif r.command then
            local r_command = type(r.command) == 'table' and r.command or r
            client.request_sync('workspace/executeCommand', r_command, 1000, args.buf)
          end
          vim.lsp._changetracking.flush(client, args.buf)
        end
      end
      vim.lsp.buf.format()
    end)

    lspmap('i', '<C-x>', 'signatureHelp', vim.lsp.buf.signature_help)
    map_to('h', 'signatureHelp', vim.lsp.buf.signature_help)
    map_to('r', 'rename', vim.lsp.buf.rename)
    map_to('u', 'references', vim.lsp.buf.references)
    map_to('a', 'codeAction', vim.lsp.buf.code_action)
    map_to('D', 'typeDefinition', vim.lsp.buf.type_definition)
    map_to('i', 'inlayHint', function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(), {bufnr = args.buf})
    end)

    if client.supports_method('textDocument/inlayHint') then
      vim.lsp.inlay_hint.enable(true, {bufnr = args.buf})
    end
  end,
})

-- Disable displaying 'HINT' diagnostics
local dfilter = {severity = {min = vim.diagnostic.severity.INFO}}
vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {virtual_text = dfilter, signs = dfilter}
)

-- Show borders in hover and signature help. Make signature help transient.
vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, {border = 'single'})
vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, {
  border = 'single',
  focus = false,
  close_events = {'CursorMoved', 'CursorMovedI', 'TextChangedI', 'TextChangedP', 'ModeChanged'},
})

-- Because default clang-format settings, as well as my zshrc, have 2 spaces
autocmd('FileType', {
  pattern = {'c', 'cpp', 'lua', 'zsh', 'yaml'},
  callback = function(_) vim.bo.ts, vim.bo.sw, vim.bo.expandtab = 2, 2, true end,
})

-- Colorscheme
-- Colorscheme - Editor elements
highlight(0, 'PMenu', {ctermbg = 8, bg = 'NvimDarkGrey3'})
highlight(0, 'LineNr', {ctermfg = 8, fg = 'NvimDarkGrey4'})
highlight(0, 'Visual', {cterm = {reverse = true}, bg = 'NvimDarkGrey4'})
highlight(0, 'DiagnosticError', {ctermfg = 9, fg = '#ff8888'})
highlight(0, 'DiagnosticHint', {ctermfg = 7, fg = 'NvimLightGrey3'})
highlight(0, 'Changed', {ctermfg = 3, fg = 'NvimDarkYellow'})      -- For gitsigns
highlight(0, 'CmpItemKind', {ctermfg = 10, fg = 'NvimLightGreen'}) -- For gitsigns

-- Colorscheme - Diff
highlight(0, 'DiffDelete', {ctermbg = 1, ctermfg = 0, bg = 'NvimDarkRed', fg = 'DarkRed'})
highlight(0, 'DiffAdd', {ctermbg = 2, ctermfg = 0, bg = 'NvimDarkGreen'})
highlight(0, 'DiffChange', {ctermbg = 11, ctermfg = 0, bg = 'NvimDarkYellow'})
highlight(0, 'DiffText', {ctermbg = 3, ctermfg = 0, bg = '#bb8800', fg = 'NvimDarkGrey1'})

-- Colorscheme - Plaintext/identifiers
highlight(0, 'Identifier', {ctermfg = 15, fg = 'fg'})
for _, v in ipairs({'Type', 'Constant', 'Function'}) do highlight(0, v, {link = 'Identifier'}) end

-- Colorscheme - Particular syntax
highlight(0, 'PreProc', {ctermfg = 10, fg = 'NvimLightGreen'})
highlight(0, 'String', {ctermfg = 13, fg = 'LightMagenta'})
highlight(0, 'Comment', {ctermfg = 3, cterm = {italic = true}, fg = '#ddaaaa', italic = true})
highlight(0, '@variable.builtin', {ctermfg = 14, fg = 'NvimLightCyan'})

-- Iterate over all hl groups and link ones ending with '.builtin' to '@variable.builtin'
for hl in vim.gsplit(vim.api.nvim_exec2('highlight', {output = true}).output, '\n') do
  -- hl looks like '<GroupName> xxx <Highlight settings for group>'
  local group = vim.split(hl, ' ')[1]
  if vim.endswith(group, '.builtin') and group ~= '@variable.builtin' then
    highlight(0, group, {link = '@variable.builtin'})
  end
end

-- Colorscheme - Generic syntax terms
highlight(0, 'Special', {ctermfg = 12, fg = '#aaccff'})
for _, v in ipairs({'Statement', 'Number', 'Boolean', 'Delimiter', 'Operator', 'Include'}) do
  highlight(0, v, {link = 'Special'})
end

-- Colorscheme - Link treesitter to sane defaults
highlight(0, '@float', {link = 'Float'})
highlight(0, '@include', {link = 'Include'})
highlight(0, '@repeat', {link = 'Repeat'})
highlight(0, '@variable', {link = 'Identifier'})
highlight(0, '@constructor', {link = 'Function'})

-- Colorscheme - Filetype-specific
highlight(0, '@string.yaml', {link = 'Identifier'})
