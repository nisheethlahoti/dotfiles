---@diagnostic disable: assign-type-mismatch, inject-field
local vim = vim
local autocmd = vim.api.nvim_create_autocmd
local command = vim.api.nvim_create_user_command
local keymap = vim.keymap.set
local highlight = vim.api.nvim_set_hl

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
    vim.system { 'git', 'clone', 'https://github.com/folke/lazy.nvim', '-b', 'stable', lazypath }:wait()
end
vim.opt.rtp:prepend(lazypath)

-- Basics
vim.o.breakindent = true                -- Wrapped part of any line also appears indented
vim.o.linebreak = true                  -- When wrapping text, break on word boundaries
vim.o.tabstop = 4                       -- No. of spaces that a <Tab> in the file counts for
vim.o.shiftwidth = 4                    -- No. of spaces to use for each step of (auto)indent
vim.o.inccommand = 'split'              -- Show effects of a command incrementally as you type
vim.o.undofile = true                   -- Keep an undo file (undo changes after closing)
vim.o.number = true                     -- Display every line's number
vim.o.lazyredraw = true                 -- Don't draw while executing macros, speeding them up
vim.o.mouse = 'a'                       -- Enable use of the mouse like a normal application
vim.o.wrap = false                      -- Disable word wrap
vim.o.scrolloff = 5                     -- Min number of screen lines to keep around the cursor
vim.o.sidescroll = 5                    -- Min number of characters to keep on screen
vim.opt.lcs:append('extends:>')         -- Show marker if line extends beyond screen
vim.opt.matchpairs:append('<:>')        -- Use '%' to navigate between '<' and '>'
vim.o.foldenable = false                -- Folds off by default
vim.o.foldmethod = 'expr'               -- Fold according to given expression (treesitter)
vim.o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.o.winborder = 'single'              -- Use single line for window borders
vim.opt.clipboard:append('unnamedplus') -- Use clipboard by default for yank/delete/paste
vim.opt.display:append('uhex')          -- Show hex for unprintable characters
vim.o.diffopt = vim.o.diffopt .. ',vertical,algorithm:histogram,indent-heuristic'

-- Set clipboard to OSC52 in case of ssh (copy into clipboard from remote locations)
if vim.env.SSH_TTY then
    local function paste() return { vim.split(vim.fn.getreg(''), '\n'), vim.fn.getregtype('') } end
    local osc52 = require('vim.ui.clipboard.osc52')
    vim.g.clipboard = {
        name = 'OSC 52',
        copy = { ['+'] = osc52.copy('+'), ['*'] = osc52.copy('*') },
        paste = { ['+'] = paste, ['*'] = paste },
    }
end

vim.g.mapleader = ' '
vim.g.python3_host_prog = vim.env.HOME .. '/basepython/bin/python'

-- Difference from original file
command('DiffOrig',
    'vnew | set buftype=nofile | read ++edit # | 0d_ | diffthis | wincmd p | diffthis', {})

-- Moving between windows
for key in vim.iter({ 'h', 'j', 'k', 'l' }) do
    keymap('t', '<C-' .. key .. '>', '<C-\\><C-n><C-w>' .. key, { desc = 'Move in direction ' .. key })
    keymap('', '<C-' .. key .. '>', '<C-w>' .. key, { desc = 'Move in direction ' .. key })
end

-- For tmux-like zooming
keymap('', '<Leader>t', ':tab split<CR>', { desc = 'Make new tab with just this window' })
keymap('', '<Leader>T', ':tabclose<CR>', { desc = 'Close tab' })

-- Search with very-magic
keymap('', '<Leader>s', ':s/\\v', { desc = 'Substitution with very-magic' })
keymap('', '<Leader>S', ':%s/\\v', { desc = 'Whole file substitution with very-magic' })

-- For clearing out last search highlight
keymap('n', '<Esc>', vim.cmd.noh, { silent = true, desc = 'Clear highlighting from last search' })

-- Commands to change directory to current file's and back to global
keymap('n', '<Leader>cd', ':lcd %:p:h | pwd<CR>', { desc = 'Change directory to file' })
keymap('n', '<Leader>cD', ':exe "lcd" getcwd(-1, -1) | pwd<CR>',
    { desc = 'Change directory to global' })

-- Delete buffer without destroying window layout
command('Bdelete', 'bp | bd<bang>#', { bang = true, desc = 'Delete buffer preserving window layout' })

-- Commands to do the intended thing on overly common typos
command('W', 'w', {})
command('Q', 'q<bang>', { bang = true })
command('Wq', 'wq', {})
command('Qa', 'qa<bang>', { bang = true })

-- Commands for editing, help, and terminal in new vertical window
command('E', 'vert new <args>', { nargs = '?', complete = 'file' })
command('Term', 'vsplit | term', { desc = 'Open terminal in vertical split window' })

-- Keymaps for browsing quickfix list
keymap('', '<Leader>q', '<cmd>copen<CR>', { desc = 'Open quickfix list' })

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
            vim.api.nvim_exec2(cmdtext .. ' ' .. cmd.args, {})
            keymap('n', '<Esc>', vim.cmd.q, { buffer = true, silent = true, desc = 'Close popup' })
        end, function(err)
            vim.notify(err, vim.log.levels.ERROR)
            vim.cmd.quit()
        end)
    end
end

command('Help', FloatingExec('set buftype=help | help'), { nargs = '?', complete = 'help' })
command('FloatMan', FloatingExec('Man! | Man'), { nargs = 1 })
local keywordmap = { [':help'] = ':Help', [':Man'] = ':FloatMan' }
autocmd('BufEnter', {
    callback = function(_) vim.o.keywordprg = keywordmap[vim.o.keywordprg] or vim.o.keywordprg end,
})

-- Convert binary file to readable bytes output and vice-versa
keymap('', '<Leader>x', function()
    vim.bo.binary = not vim.bo.binary
    vim.cmd('%!xxd' .. (vim.bo.binary and ' -r' or ''))
end, { desc = 'Toggle binary/hex view' })

-- Set wrap only for certain file types
local wrap_ft = { 'text', 'markdown' }
autocmd('FileType', { callback = function(e) vim.wo.wrap = vim.list_contains(wrap_ft, e.match) end })

-- Color order in 16-color (i.e. cterm color #1 is Red, #2 is Green, etc.)
local colors = { 'Red', 'Green', 'Yellow', 'Blue', 'Magenta', 'Cyan' }

-- Setup plugins
require('lazy').setup {
    -- Editing motions
    'tpope/vim-surround',              -- Surround with parentheses/HTML-tags etc.
    'tpope/vim-repeat',                -- Use '.' with several plugins
    'jeetsukumaran/vim-indentwise',    -- Motions over indented blocks
    'michaeljsmith/vim-indent-object', -- Indent textobjects

    -- General
    {
        'simnalamburt/vim-mundo', -- Undo tree visualizer
        keys = { { 'U', ':MundoToggle<CR>', desc = 'Toggle undo tree' } },
    },
    {
        'stevearc/oil.nvim', -- Directory browser
        lazy = false,
        opts = { delete_to_trash = true },
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        keys = { { '-', function() require('oil').open() end, desc = 'Open parent directory' } },
    },
    'tpope/vim-speeddating',         -- Increment/decrement dates
    {
        'nvim-lualine/lualine.nvim', -- Better status line
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        opts = { options = { theme = 'nord' } },
    },
    { 'stevearc/dressing.nvim', opts = {} }, -- Better UI for input and select
    {
        'ibhagwan/fzf-lua',                  -- Vim bindings for fzf
        dependencies = { 'nvim-tree/nvim-web-devicons', { 'junegunn/fzf', build = './install --all' } },
        config = function()
            local fzf = require('fzf-lua')
            keymap('', '<Leader>f', fzf.files, { desc = 'Fzf files' })
            keymap('', '<Leader>l', fzf.live_grep, { desc = 'Fzf live grep' })
            keymap('', '<Leader>b', fzf.buffers, { desc = 'Fzf Buffers' })
            keymap('', '<Leader>j', fzf.jumps, { desc = 'Fzf Jumps' })
            keymap('', '<Leader>/', fzf.lgrep_curbuf, { desc = 'Fzf-based buffer search' })
            keymap('', '<Leader>h', fzf.help_tags, { desc = 'Fzf-based help search' })
            fzf.setup { keymap = { fzf = { ['ctrl-q'] = 'select-all+accept' } } } -- Send results to quickfix
            autocmd('FileType', {                                                 -- Open quickfix only in fzf
                pattern = 'qf',
                callback = vim.schedule_wrap(function() vim.cmd('cclose | FzfLua quickfix') end),
            })
        end,
    },
    {
        'tpope/vim-fugitive', -- Git usage integration
        config = function()
            autocmd('User', { -- Modify `rf` to use `--committer-date-is-author-date`
                pattern = { 'FugitiveIndex', 'FugitivePager', 'FugitiveObject' },
                callback = function()
                    local rf_map = vim.fn.maparg('rf', 'n', false, true)
                    if not rf_map.rhs then return end -- No mapping found, nothing to do
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
                local function get_opts(desc) return { buffer = bufnr, silent = true, desc = desc } end
                local gitsigns = require('gitsigns')
                keymap({ 'o', 'x' }, 'ih', assert(gitsigns.select_hunk), get_opts('Select hunk'))

                for dest, key in pairs({ next = ']c', prev = '[c' }) do
                    keymap('', key, function()
                        if vim.wo.diff then vim.cmd.normal({ key, bang = true }) else gitsigns.nav_hunk(dest) end ---@diagnostic disable-line: param-type-mismatch
                    end, get_opts('Navigate to' .. dest .. ' hunk'))
                end
            end,
        },
    },
    {
        'rmagatti/auto-session',          -- Remote persistence for neovim
        enabled = vim.env.SSH_TTY ~= nil, -- Only use in SSH environments
        opts = { log_level = 'error' },
    },
    {
        'saghen/blink.cmp', -- Autocomplete
        version = '1.*',
        opts = {
            keymap = {
                preset = 'none',
                ['<C-CR>'] = { 'show', 'select_and_accept' },
                ['<Tab>'] = { 'select_next', 'fallback' },
                ['<S-Tab>'] = { 'select_prev', 'fallback' },
            },
            completion = {
                documentation = { auto_show = true },
                list = { selection = { preselect = false } },
            },
            cmdline = {
                keymap = { preset = 'inherit' },
                completion = {
                    menu = { auto_show = true },
                    list = { selection = { preselect = false } },
                },
            },
            sources = {
                default = { 'lazydev', 'lsp', 'path', 'snippets', 'buffer' },
                providers = {
                    lazydev = { name = 'LazyDev', module = 'lazydev.integrations.blink', score_offset = 100 },
                },
            },
        },
    },
    {
        'folke/which-key.nvim', -- Keymap helper
        event = 'VeryLazy',
        opts = { spec = {
            { '<Leader>a', group = 'AI chat' },
            { '<Leader>]', group = 'Swap with next' },
            { '<Leader>[', group = 'Swap with previous' },
            { '<BS>',      group = 'Debugging' },
            { 'gr',        group = 'LSP' },
            { '<Leader>c', group = 'Change working dir' },
        } },
        keys = { {
            '<leader>?',
            function() require('which-key').show { global = false } end,
            desc = 'Buffer Local Keymaps (which-key)',
        } },
    },

    -- Language awareness
    {
        'nvim-treesitter/nvim-treesitter', -- Language syntax parsing
        build = ':TSUpdate',
        main = 'nvim-treesitter.configs',
        opts = {
            ensure_installed = { 'bash', 'cpp', 'lua', 'python', 'rust', 'vim', 'vimdoc' },
            auto_install = true, -- On entering new buffer, install its parser if available
            highlight = { enable = true, additional_vim_regex_highlighting = false },
            incremental_selection = {
                enable = true,
                keymaps = { node_incremental = '/', node_decremental = '?' },
            },
        },
    },
    {
        'nvim-treesitter/nvim-treesitter-textobjects', -- Text-objects based on treesitter
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        main = 'nvim-treesitter.configs',
        opts = function(_, opts)
            local maps = { a = 'parameter', f = 'function', c = 'class' }
            local swap_type = { a = '', f = '.outer', c = '.outer' }
            local select_maps, swap_next_maps, swap_prev_maps = {}, {}, {}
            for k, v in pairs(maps) do
                select_maps['a' .. k] = '@' .. v .. '.outer'
                select_maps['i' .. k] = '@' .. v .. '.inner'
                swap_next_maps['<Leader>]' .. k] = '@' .. v .. swap_type[k]
                swap_prev_maps['<Leader>[' .. k] = '@' .. v .. swap_type[k]
            end

            opts.textobjects = {
                select = { enable = true, keymaps = select_maps },
                swap = { enable = true, swap_next = swap_next_maps, swap_previous = swap_prev_maps },
            }
        end,
    },
    {
        'mfussenegger/nvim-dap', -- Debug adapter protocol
        config = function()
            local dap = require('dap')
            dap.adapters.python = {
                type = 'executable',
                command = vim.env.HOME .. '/.local/share/nvim/mason/bin/debugpy-adapter',
            }
            dap.configurations.python = { {
                -- nvim-dap options
                type = 'python', -- this links to the adapter definition: `dap.adapters.python`
                request = 'launch',
                name = 'Launch file',
                -- debugpy options, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings
                program = '${file}', -- This configuration will launch the current file if used.
                args = function()
                    local infile = vim.fn.input('Arguments file: ')
                    return infile == '' and {} or vim.fn.readfile(infile)
                end,
                pythonPath = function() return vim.fn.system('which python3'):sub(1, -2) end,
            } }
            keymap('', '<BS>c', dap.continue, { desc = 'Continue debugging' })
            keymap('', '<BS>n', dap.step_over, { desc = 'Step over' })
            keymap('', '<BS>s', dap.step_into, { desc = 'Step into' })
            keymap('', '<BS>r', dap.step_out, { desc = 'Step out' })
            keymap('', '<BS>u', dap.run_to_cursor, { desc = 'Run to cursor' })
            keymap('', '<BS>b', dap.toggle_breakpoint, { desc = 'Toggle breakpoint' })
            keymap('', '<BS>R', dap.repl.open, { desc = 'Open REPL' })
            keymap('', '<BS>l', dap.list_breakpoints, { desc = 'Browse breakpoints' })
            keymap('', '<BS>B', function()
                vim.ui.input({ prompt = 'Breakpoint condition: ' }, dap.set_breakpoint)
            end, { desc = 'Conditional breakpoint' })
            keymap('', '<BS>q', dap.terminate, { desc = 'Terminate debugging' })

            -- Attach to running process open on some port on localhost
            dap.adapters.socket = function(cb, cfg) cb { type = 'server', port = cfg.port } end
            keymap('', '<BS>A', function()
                dap.run {
                    name = 'Attach to running process',
                    type = 'socket',
                    request = 'attach',
                    port = tonumber(vim.fn.input('Port: ')),
                }
            end, { desc = 'DAP attach to running process' })
        end,
    },
    {
        'rcarriga/nvim-dap-ui', -- Frontend for nvim-dap
        dependencies = { 'mfussenegger/nvim-dap', 'nvim-neotest/nvim-nio' },
        config = function()
            local dap = require('dap')
            local dapui = require('dapui')
            dapui.setup()
            keymap('', '<BS>w', dapui.toggle, { desc = 'Toggle debug UI' })
            dap.listeners.before.attach.dapui_config = dapui.open
            dap.listeners.before.launch.dapui_config = dapui.open
            dap.listeners.before.event_terminated.dapui_config = dapui.close
        end,
    },
    { 'mason-org/mason.nvim',   opts = {} }, -- Package manager for LSP
    {
        'mason-org/mason-lspconfig.nvim',    -- Configs for LSP servers
        dependencies = { 'mason-org/mason.nvim', 'neovim/nvim-lspconfig' },
        opts = { ensure_installed = { 'clangd', 'pyright', 'ruff', 'lua_ls', 'jsonls' } },
    },
    {
        'stevearc/aerial.nvim', -- Code outline window
        dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
        opts = { on_attach = function()
            keymap('', '<Leader>o', require('aerial').toggle, { desc = 'Toggle code outline' })
        end },
    },

    -- AI
    {
        'github/copilot.vim', -- Github copilot support
        config = function()
            vim.g.copilot_filetypes = { text = false }
            vim.g.copilot_no_tab_map = true
            keymap('i', '<C-space>', 'copilot#Accept("")', { expr = true, replace_keycodes = false })
            keymap('i', '<C-right>', '<Plug>(copilot-accept-word)', { desc = "Accept Copilot's next word" })
            keymap('i', '<C-up>', '<Plug>(copilot-previous)', { desc = 'Previous Copilot suggestion' })
            keymap('i', '<C-down>', '<Plug>(copilot-next)', { desc = 'Next Copilot suggestion' })
        end,
    },
    {
        'folke/sidekick.nvim', -- Next edit suggestion + LLM Chat
        config = function()
            require('sidekick').setup { cli = { mux = { enabled = true } } }
            autocmd('OptionSet', { -- Disable next-edit-suggestion in diff mode
                pattern = 'diff',
                callback = function()
                    -- Temporarily store sidekick_nes value in new variable called sidekick_nes_nondiff
                    if vim.v.option_new then
                        vim.b.sidekick_nes_nondiff = vim.b.sidekick_nes
                        vim.b.sidekick_nes = false
                    else
                        vim.b.sidekick_nes = vim.b.sidekick_nes_nondiff
                    end
                end,
            })
            autocmd('FileType', { -- Disable next-edit-suggestion for plaintext files
                pattern = { 'text' },
                callback = function() vim.b.sidekick_nes = false end,
            })
            keymap('n', '<Leader>aa', ':Sidekick cli toggle<cr>', { desc = 'Toggle AI chat' })
            keymap('n', '<Leader>as', ':Sidekick cli select<cr>', { desc = 'Select AI model' })
            keymap('n', '<Leader>af', ':Sidekick cli send msg="{file}"<cr>', { desc = 'Send File' })
            keymap('', '<Leader>at', ':Sidekick cli send msg="{this}"<cr>', { desc = 'Send This' })
            keymap('', '<Leader>ap', ':Sidekick cli prompt<cr>', { desc = 'AI Prompt' })
            keymap('n', '<Tab>', function()
                -- if there is a next edit, jump to it, otherwise apply it if any
                if not require('sidekick').nes_jump_or_apply() then
                    return '<Tab>' -- fallback to normal tab
                end
            end, { expr = true, desc = 'Goto/Apply Next Edit Suggestion' })
        end,
    },

    -- Language specific
    {
        'folke/lazydev.nvim',
        ft = 'lua', -- only load on lua files
        opts = {
            -- Load luvit types when the `vim.uv` word is found
            library = { { path = '${3rd}/luv/library', words = { 'vim%.uv' } } },
        },
    },
    {
        'MeanderingProgrammer/render-markdown.nvim',
        config = function()
            require('render-markdown').setup {}
            for i, c in ipairs({ 5, 4, 6, 2, 3, 1 }) do -- Set highlight colors in VIBGYOR order
                highlight(0, 'RenderMarkdownH' .. i .. 'Bg', { bg = 'NvimDark' .. colors[c], ctermbg = c })
            end
            autocmd('OptionSet', { -- Disable in diff mode
                pattern = 'diff',
                callback = function()
                    if vim.bo.filetype ~= 'markdown' then return end
                    vim.cmd('RenderMarkdown ' .. (vim.v.option_new and 'disable' or 'enable'))
                end,
            })
        end,
        dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
    },
}

-- Keybindings and default changes on attaching LSP
autocmd('LspAttach', {
    callback = function(args)
        local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
        assert(client.server_capabilities, 'LSP client has no server capabilities')
        client.server_capabilities.semanticTokensProvider = nil -- Disable semantic tokens

        -- Server-specific: disable ruff's hover in favor of pyright
        if client.name == 'ruff' then client.server_capabilities.hoverProvider = false end

        local function map_to(key, method, cmd)
            if client:supports_method('textDocument/' .. method) then
                keymap('', 'gr' .. key, cmd, { silent = true, buffer = args.buf, desc = 'LSP ' .. method })
            end
        end

        map_to('f', 'formatting', function()
            -- TODO(neovim/neovim/24168): Replace below with 2 lines using vim.lsp.buf.code_action
            for _, action in ipairs({ 'source.fixAll', 'source.organizeImports' }) do
                local params = vim.lsp.util.make_range_params(nil, client.offset_encoding)
                params.context = { only = { action }, diagnostics = {} }
                local result = client:request_sync('textDocument/codeAction', params, 1000, args.buf)
                for _, r in ipairs((result or {}).result or {}) do
                    if not (r.command or r.edit) then
                        r = assert(client:request_sync('codeAction/resolve', r, 1000, args.buf)).result
                    end
                    if r.edit then
                        vim.lsp.util.apply_workspace_edit(r.edit, client.offset_encoding)
                    elseif r.command then
                        local r_command = type(r.command) == 'table' and r.command or r
                        client:request_sync('workspace/executeCommand', r_command, 1000, args.buf)
                    end
                    vim.lsp._changetracking.flush(client, args.buf)
                end
            end
            vim.lsp.buf.format()
        end)

        local buf = { bufnr = args.buf }
        map_to('h', 'inlayHint',
            function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(buf), buf) end)

        if client:supports_method('textDocument/codeLens') then
            vim.lsp.codelens.refresh()
            autocmd(
                { 'BufEnter', 'CursorHold', 'InsertLeave' },
                { buffer = args.buf, callback = vim.lsp.codelens.refresh }
            )
        end
    end,
})

-- Disable displaying 'HINT' diagnostics + show virtual_text by default
local dfilter = { severity = { min = vim.diagnostic.severity.INFO } }
vim.diagnostic.config { virtual_text = dfilter, signs = dfilter }

-- Custom LSP configurations
vim.lsp.config('clangd', { cmd = { 'clangd', '--clang-tidy', '--header-insertion=never' } })

-- Because default clang-format settings, as well as my zshrc, have 2 spaces
autocmd('FileType', {
    pattern = { 'c', 'cpp', 'zsh', 'yaml' },
    callback = function(_) vim.bo.ts, vim.bo.sw, vim.bo.expandtab = 2, 2, true end,
})

-- Colorscheme
-- Colorscheme - Editor elements
highlight(0, 'PMenu', { ctermbg = 8, bg = 'NvimDarkGrey3' })
highlight(0, 'LineNr', { ctermfg = 8, fg = 'NvimDarkGrey4' })
highlight(0, 'Visual', { cterm = { reverse = true }, bg = 'NvimDarkGrey4' })
highlight(0, 'DiagnosticError', { ctermfg = 9, fg = '#ff8888' })
highlight(0, 'DiagnosticHint', { ctermfg = 7, fg = 'NvimLightGrey3' })
highlight(0, 'Changed', { ctermfg = 3, fg = 'NvimDarkYellow' })      -- For gitsigns
highlight(0, 'CmpItemKind', { ctermfg = 10, fg = 'NvimLightGreen' }) -- For gitsigns

-- Colorscheme - Diff
highlight(0, 'DiffDelete', { ctermbg = 1, ctermfg = 0, bg = 'NvimDarkRed', fg = 'DarkRed' })
highlight(0, 'DiffAdd', { ctermbg = 2, ctermfg = 0, bg = 'NvimDarkGreen' })
highlight(0, 'DiffChange', { ctermbg = 11, ctermfg = 0, bg = 'NvimDarkYellow' })
highlight(0, 'DiffText', { ctermbg = 3, ctermfg = 0, bg = '#bb8800', fg = 'NvimDarkGrey1' })

-- Colorscheme - Plaintext/identifiers
highlight(0, 'Identifier', { ctermfg = 15, fg = 'fg' })
for _, v in ipairs({ 'Type', 'Constant', 'Function' }) do highlight(0, v, { link = 'Identifier' }) end

-- Colorscheme - Particular syntax
highlight(0, 'PreProc', { ctermfg = 10, fg = 'NvimLightGreen' })
highlight(0, 'String', { ctermfg = 13, fg = 'LightMagenta' })
highlight(0, 'Comment', { ctermfg = 3, cterm = { italic = true }, fg = '#ddaaaa', italic = true })
highlight(0, '@variable.builtin', { ctermfg = 14, fg = 'NvimLightCyan' })
highlight(0, '@string.documentation', { ctermfg = 13, cterm = { italic = true }, fg = '#ee99bb' })
highlight(0, '@comment.documentation', { link = '@string.documentation' })

-- Iterate over all hl groups and link ones ending with '.builtin' to '@variable.builtin'
for hl in vim.gsplit(vim.api.nvim_exec2('highlight', { output = true }).output, '\n') do
    -- hl looks like '<GroupName> xxx <Highlight settings for group>'
    local group = assert(vim.split(hl, ' ')[1])
    if vim.endswith(group, '.builtin') and group ~= '@variable.builtin' then
        highlight(0, group, { link = '@variable.builtin' })
    end
end

-- Colorscheme - Generic syntax terms
highlight(0, 'Special', { ctermfg = 12, fg = '#aaccff' })
for _, v in ipairs({ 'Statement', 'Number', 'Boolean', 'Delimiter', 'Operator', 'Include' }) do
    highlight(0, v, { link = 'Special' })
end

-- Colorscheme - Link treesitter to sane defaults
highlight(0, '@float', { link = 'Float' })
highlight(0, '@include', { link = 'Include' })
highlight(0, '@repeat', { link = 'Repeat' })
highlight(0, '@variable', { link = 'Identifier' })
highlight(0, '@constructor', { link = 'Function' })

-- Colorscheme - Filetype-specific
highlight(0, '@string.yaml', { link = 'Identifier' })
