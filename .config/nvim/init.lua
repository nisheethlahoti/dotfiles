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
  local osc52 = require('vim.ui.clipboard.osc52')
  vim.g.clipboard = {
    name = 'OSC 52',
    copy = {['+'] = osc52.copy('+'), ['*'] = osc52.copy('*')},
    paste = {['+'] = paste, ['*'] = paste},
  }
end

vim.g.mapleader = ' '
if vim.fn.isdirectory(os.getenv('HOME')..'/micromamba') then
  vim.g.python3_host_prog = os.getenv('HOME')..'/micromamba/bin/python'
end

-- Difference from original file
command('DiffOrig',
  'vnew | set buftype=nofile | read ++edit # | 0d_ | diffthis | wincmd p | diffthis', {})

-- Moving between windows
for key in vim.iter({'h', 'j', 'k', 'l'}) do
  keymap('t', '<C-'..key..'>', '<C-\\><C-n><C-w>'..key, {desc = 'Move in direction '..key})
  keymap('', '<C-'..key..'>', '<C-w>'..key, {desc = 'Move in direction '..key})
end

-- For tmux-like zooming
keymap('', '<Leader>t', ':tab split<CR>', {desc = 'Make new tab with just this window'})
keymap('', '<Leader>T', ':tabclose<CR>', {desc = 'Close tab'})

-- Replacing shortcuts, plus use very-magic for regexes
keymap('', '/', '/\\v')
keymap('', '?', '?\\v')
keymap('', '<Leader>s', ':s/\\v', {desc = 'Substitution with very-magic'})
keymap('', '<Leader>S', ':%s/\\v', {desc = 'Whole file substitution with very-magic'})

-- For clearing out last search highlight
keymap('n', '<Esc>', vim.cmd.noh, {silent = true, desc = 'Clear highlighting from last search'})

-- Commands to change directory to current file's and back to global
keymap('n', '<Leader>cd', ':lcd %:p:h | pwd<CR>', {desc = 'Change directory to file'})
keymap('n', '<Leader>cD', ':exe "lcd" getcwd(-1, -1) | pwd<CR>',
  {desc = 'Change directory to global'})

-- Delete buffer without destroying window layout
command('Bdelete', 'bp | bd<bang>#', {bang = true, desc = 'Delete buffer preserving window layout'})

-- Commands to do the intended thing on overly common typos
command('W', 'w', {})
command('Q', 'q<bang>', {bang = true})
command('Wq', 'wq', {})
command('Qa', 'qa<bang>', {bang = true})

-- Commands for editing, help, and terminal in new vertical window
command('E', 'vert new <args>', {nargs = '?', complete = 'file'})
command('Term', 'vsplit | term', {desc = 'Open terminal in vertical split window'})

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
      keymap('n', '<Esc>', vim.cmd.q, {buffer = true, silent = true, desc = 'Close popup'})
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
end, {desc = 'Toggle binary/hex view'})

-- Set wrap only for certain file types
local wrap_ft = {'text', 'markdown'}
autocmd('FileType', {callback = function(e) vim.wo.wrap = vim.list_contains(wrap_ft, e.match) end})

-- Setup plugins
require('lazy').setup {
  -- Editing motions
  'tpope/vim-surround',              -- Surround with parentheses/HTML-tags etc.
  'tpope/vim-repeat',                -- Use '.' with several plugins
  'jeetsukumaran/vim-indentwise',    -- Motions over indented blocks
  'michaeljsmith/vim-indent-object', -- Indent textobjects
  {
    'ggandor/flit.nvim',             -- Better f/F/t/T
    dependencies = {'ggandor/leap.nvim'},
    opts = {labeled_modes = 'nx'},
  },

  -- General
  'tpope/vim-vinegar',           -- Browsing files
  {
    'nvim-lualine/lualine.nvim', -- Better status line
    dependencies = {'nvim-tree/nvim-web-devicons'},
    opts = {options = {theme = 'nord'}},
  },
  {'stevearc/dressing.nvim', opts = {}}, -- Better UI for input and select
  {
    'ibhagwan/fzf-lua',                  -- Vim bindings for fzf
    dependencies = {'nvim-tree/nvim-web-devicons', {'junegunn/fzf', build = './install --all'}},
    config = function()
      local fzf = require('fzf-lua')
      keymap('', '<Leader>o', fzf.files, {desc = 'Fuzzy find files'})
      keymap('', '<Leader>l', fzf.live_grep, {desc = 'Live grep'})
      keymap('', '<Leader>h', fzf.command_history, {desc = 'Show command history'})
    end,
  },
  {
    'tpope/vim-fugitive', -- Git usage integration
    config = function()
      autocmd('User', {   -- Modify `rf` to use `--committer-date-is-author-date`
        pattern = {'FugitiveIndex', 'FugitivePager', 'FugitiveObject'},
        callback = function()
          local rf_map = vim.fn.maparg('rf', 'n', false, true)
          if not rf_map.rhs then return end  -- No mapping found, nothing to do
          rf_map.rhs = rf_map.rhs:gsub(' rebase ', ' rebase --committer-date-is-author-date ')
          vim.fn.mapset(rf_map)
        end,
      })
    end,
  },
  {
    'lewis6991/gitsigns.nvim', -- hunk object and signs for changed lines
    opts = {
      on_attach = function(bufnr)
        local function get_opts(desc)
          return {buffer = bufnr, silent = true, desc = desc}
        end
        local gitsigns = require('gitsigns')
        keymap({'o', 'x'}, 'ih', gitsigns.select_hunk, get_opts('Select hunk'))

        for dest, key in pairs({next = ']c', prev = '[c'}) do
          keymap('', key, function()
            if vim.wo.diff then vim.cmd.normal({key, bang = true}) else gitsigns.nav_hunk(dest) end
          end, get_opts('Navigate to'..dest..' hunk'))
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
          ['<C-CR>'] = cmp.mapping.confirm({desc = 'Confirm completion'}),
          ['<Tab>'] = cmp.mapping.select_next_item({desc = 'Select next item'}),
          ['<S-Tab>'] = cmp.mapping.select_prev_item({desc = 'Select previous item'}),
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
  {
    'folke/which-key.nvim', -- Keymap helper
    event = 'VeryLazy',
    opts = {spec = {
      {'<Leader>a',        group = 'AI chat'},
      {'<Leader>]',        group = 'Swap with next'},
      {'<Leader>[',        group = 'Swap with previous'},
      {'<BS>',             group = 'Debugging'},
      {'<Leader><Leader>', group = 'LSP'},
      {'<Leader>c',        group = 'Change working dir'},
    }},
    keys = {{
      '<leader>?',
      function() require('which-key').show {global = false} end,
      desc = 'Buffer Local Keymaps (which-key)',
    }},
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
      local maps = {a = 'parameter', f = 'function', c = 'class'}
      local select_maps, swap_next_maps, swap_prev_maps = {}, {}, {}
      for k, v in pairs(maps) do
        select_maps['a'..k] = '@'..v..'.outer'
        select_maps['i'..k] = '@'..v..'.inner'
        swap_next_maps['<Leader>]'..k] = '@'..v..'.outer'
        swap_prev_maps['<Leader>['..k] = '@'..v..'.outer'
      end

      opts.textobjects = {
        select = {enable = true, keymaps = select_maps},
        swap = {enable = true, swap_next = swap_next_maps, swap_previous = swap_prev_maps},
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
      keymap('', '<BS>c', dap.continue, {desc = 'Continue debugging'})
      keymap('', '<BS>n', dap.step_over, {desc = 'Step over'})
      keymap('', '<BS>s', dap.step_into, {desc = 'Step into'})
      keymap('', '<BS>r', dap.step_out, {desc = 'Step out'})
      keymap('', '<BS>b', dap.toggle_breakpoint, {desc = 'Toggle breakpoint'})
      keymap('', '<BS>R', dap.repl.open, {desc = 'Open REPL'})
      keymap('', '<BS>l', dap.list_breakpoints, {desc = 'Fill quickfix list with breakpoints'})
      keymap('', '<BS>B', function() vim.ui.input('Breakpoint condition: ', dap.set_breakpoint) end,
        {desc = 'Conditional breakpoint'})
      keymap('', '<BS>q', dap.terminate, {desc = 'Terminate debugging'})
    end,
  },
  {
    'rcarriga/nvim-dap-ui', -- Frontend for nvim-dap
    dependencies = {'mfussenegger/nvim-dap', 'nvim-neotest/nvim-nio'},
    config = function()
      local dap = require('dap')
      local dapui = require('dapui')
      dapui.setup()
      keymap('', '<BS>w', dapui.toggle, {desc = 'Toggle debug UI'})
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
  {
    'stevearc/aerial.nvim', -- Code outline window
    dependencies = {'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons'},
    opts = {on_attach = function()
      keymap('', '<Leader>b', require('aerial').toggle, {desc = 'Toggle browsing code'})
    end},
  },

  -- AI
  {
    'github/copilot.vim', -- Github copilot support
    config = function()
      vim.g.copilot_no_tab_map = true
      keymap('i', '<C-space>', 'copilot#Accept("")', {expr = true, replace_keycodes = false})
      keymap('i', '<C-right>', '<Plug>(copilot-accept-word)', {desc = "Accept Copilot's next word"})
      keymap('i', '<C-up>', '<Plug>(copilot-previous)', {desc = 'Previous Copilot suggestion'})
      keymap('i', '<C-down>', '<Plug>(copilot-next)', {desc = 'Next Copilot suggestion'})
    end,
  },
  {
    'robitx/gp.nvim', -- LLM Chat
    config = function()
      local gp = require('gp')
      local disable_agents = {} -- Disable non-best agents of providers
      for _, v in ipairs({'Claude-3-Haiku', 'GPT4o-mini'}) do
        table.insert(disable_agents, {name = 'Chat'..v, disable = true})
        table.insert(disable_agents, {name = 'Code'..v, disable = true})
      end

      gp.setup({
        providers = {
          anthropic = {disable = false},
          openai = {disable = true},
          copilot = {
            disable = false,
            secret = vim.tbl_values(
              vim.json.decode(vim.fn.readfile(vim.env.HOME..'/.config/github-copilot/apps.json')[1])
            )[1]['oauth_token'],
          },
        },
        agents = disable_agents,
      })

      -- Chat commands
      vim.keymap.set('', '<Leader>aa', ':GpChatToggle vsplit<cr>', {desc = 'Toggle chat'})
      vim.keymap.set('', '<Leader>aA', ':GpChatNew vsplit<cr>', {desc = 'New chat'})
      vim.keymap.set('', '<Leader>af', ':GpChatFinder<cr>', {desc = 'Find chat'})
      vim.keymap.set('x', '<Leader>ap', ':GpChatPaste<cr>', {desc = 'Paste in chat'})

      -- Credit: https://github.com/Robitx/gp.nvim/issues/191#issuecomment-2271698759
      function _G.gp_diff(line1, line2)
        vim.ui.input(gp.get_command_agent().cmd_prefix, function(prompt)
          if prompt == nil or prompt == '' then return end
          local contents = vim.api.nvim_buf_get_lines(vim.api.nvim_get_current_buf(), 0, -1, false)
          vim.cmd('vnew | set buftype=nofile | set bufhidden=wipe')
          vim.api.nvim_buf_set_lines(vim.api.nvim_get_current_buf(), 0, -1, false, contents)
          vim.cmd(line1..','..line2..'GpRewrite '..prompt)
          vim.defer_fn(function() vim.cmd('diffthis | wincmd p | diffthis') end, 1000)
        end)
      end

      -- Prompt commands
      vim.cmd('command! -range GpDiff lua gp_diff(<line1>, <line2>)')
      vim.keymap.set('x', '<Leader>aw', ':GpDiff<CR>', {desc = 'Copilot rewrite'})
      vim.keymap.set('x', '<Leader>ai', ':GpImplement<cr>', {desc = 'Implement selected text'})

      -- Generic commands
      vim.keymap.set('', '<Leader>ac', ':GpContext vsplit<cr>', {desc = 'Open project context'})
      vim.keymap.set('', '<Leader>ax', '<cmd>GpStop<cr>', {desc = 'Stop agent'})
      vim.keymap.set('', '<Leader>an', '<cmd>GpNextAgent<cr>', {desc = 'Next agent'})
    end,
  },

  -- Language specific
  {
    'MeanderingProgrammer/render-markdown.nvim',
    opts = {},
    dependencies = {'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons'},
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
        keymap(mode, key, cmd, {silent = true, buffer = args.buf, desc = 'LSP '..method})
      end
    end

    local function map_to(key, method, cmd) lspmap('', '<Leader><Leader>'..key, method, cmd) end

    map_to('f', 'formatting', function()
      -- TODO(neovim/neovim/24168): Replace below with 2 lines using vim.lsp.buf.code_action
      for _, action in ipairs({'source.fixAll', 'source.organizeImports'}) do
        local params = vim.lsp.util.make_range_params()
        params.context = {only = {action}, diagnostics = {}}
        local result = client.request_sync('textDocument/codeAction', params, 1000, args.buf)
        for _, r in ipairs((result or {}).result or {}) do
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

    if client.supports_method('textDocument/codeLens') then
      vim.lsp.codelens.refresh()
      vim.api.nvim_create_autocmd(
        {'BufEnter', 'CursorHold', 'InsertLeave'},
        {buffer = args.buf, callback = vim.lsp.codelens.refresh}
      )
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
