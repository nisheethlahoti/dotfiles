" Basics
set breakindent        " Wrapped part of any line also appears indented
set linebreak          " When wrapping text, break on word boundaries
set tabstop=4          " Number of spaces that a <Tab> in the file counts for
set shiftwidth=4       " Number of spaces to use for each step of (auto)indent
set inccommand=split   " Shows the effects of a command incrementally, as you type.
set undofile           " Keep an undo file (undo changes after closing)
set number             " Display every line's number
set lazyredraw         " Don't draw while executing macros (making them faster)
set mouse=a            " Enables the use of the mouse like a normal application
set nowrap             " Disables word wrap
set scrolloff=5        " Minimal number of screen lines to keep around the cursor
set sidescroll=5       " Minimum number of characters to keep on screen
set lcs+=extends:>     " Show marker if line extends beyond screen
set matchpairs+=<:>    " Use '%' to navigate between '<' and '>'
set nofoldenable       " Folds off by default
set foldmethod=expr    " Fold according to given expression (treesitter)
set foldexpr=nvim_treesitter#foldexpr()
set clipboard+=unnamedplus    " Uses clipboard by default for yank/delete/paste

let mapleader = " "
if isdirectory($HOME.'/micromamba')
	let g:python3_host_prog = $HOME.'/micromamba/bin/python'
endif

" See the difference between the current buffer and the file it has been loaded from
command DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis | wincmd p | diffthis

" Moving between windows, and escaping terminal
tnoremap <C-h> <C-\><C-n><C-w>h
tnoremap <C-j> <C-\><C-n><C-w>j
tnoremap <C-k> <C-\><C-n><C-w>k
tnoremap <C-l> <C-\><C-n><C-w>l
tnoremap <C-t> <C-\><C-n>gt

" Because I often unintentionally press PageUp and PageDown
map <PageUp> <nop>
map! <PageUp> <nop>
map <PageDown> <nop>
map! <PageDown> <nop>

" Replacing shortcuts, plus use very-magic for regexes
map <A-/> /\v
map <A-?> ?\v
map <Leader>s :s/\v
map <Leader>S :%s/\v

" For clearing out last search highlight
nnoremap <silent> <Esc> :noh<CR>

" Delete buffer without destroying window layout
command -bang Bdelete bp | bd<bang>#

" Commands to change directory to current file's and back to global
nnoremap <silent> <Leader>cd :lcd %:p:h \| pwd<CR>
nnoremap <silent> <Leader>cD :exe "lcd" getcwd(-1, -1) \| pwd<CR>

" Commands to do the intended thing on overly common typos
command W w
command -bang Q q<bang>
command Wq wq
command -bang Qa qa<bang>

" Commands for editing, help, and terminal in new vertical window
command -nargs=? -complete=file E vert new <args>
command Term vsplit | term

function FloatingExec(...) abort
	call nvim_open_win(nvim_create_buf(0, 1), 1, {
		\'relative': 'editor',
		\'row': float2nr(0.1 * &lines),
		\'col': float2nr(0.1 * &columns),
		\'height': float2nr(0.8 * &lines),
		\'width': float2nr(0.8 * &columns),
	    \'border': 'single',
	\})
	try
		execute join(a:000, ' ')
		nnoremap <buffer> <silent> <Esc> :q<CR>
	catch
		quit
	endtry
endfunction

" Help and man in floating windows (supporting keywordprg)
command -nargs=? -complete=help Help call FloatingExec("set buftype=help | help", <q-args>)
command -nargs=1 FloatMan call FloatingExec("Man! | Man", <q-args>)
au BufEnter * if &keywordprg == ":help" | set keywordprg=:Help | endif
au BufEnter * if &keywordprg == ":Man" | set keywordprg=:FloatMan | endif

" Convert binary file to readable bytes output and vice-versa
function Xxd()
	if &binary
		%!xxd
		set nobinary
	else
		set binary
		%!xxd -r
	endif
endfunction

noremap <Leader>x :call Xxd()<CR>

" Text file editing
au FileType text set wrap

" Moving between windows
noremap <C-h> <C-w>h
noremap <C-j> <C-w>j
noremap <C-k> <C-w>k
noremap <C-l> <C-w>l

" For netrw (and hence vinegar)
let g:netrw_bufsettings = 'nomodifiable nomodified readonly nobuflisted nowrap number'
au FileType netrw setl bufhidden=delete

" For fugitive plugin
set diffopt+=vertical     " Always opens diffs vertically

" For fzf plugin (\o for opening file and \g for searching through files)
noremap <Leader>o :Files<CR>
noremap <Leader>l :Rg<CR>
noremap <Leader>h :History:<CR>
let g:fzf_layout = {'window': {'width': 0.8, 'height': 0.8, 'relative': 'editor'}}

" Plugins
call plug#begin('~/.plugins/neovim')
	" General
	Plug 'tpope/vim-fugitive'                             " Git usage integration
	Plug 'tpope/vim-surround'                             " Surround with parentheses/HTML-tags etc.
	Plug 'tpope/vim-vinegar'                              " Browsing files
	Plug 'tpope/vim-repeat'                               " Use '.' with vim-surround
	Plug 'nvim-lualine/lualine.nvim'                      " Better status line
	Plug 'junegunn/fzf', {'do': './install --all'}        " Fuzzy finder
	Plug 'junegunn/fzf.vim'                               " Vim bindings for fzf
	Plug 'nvim-lua/plenary.nvim'                          " Common functions for neovim
	Plug 'lewis6991/gitsigns.nvim'                        " hunk object and signs for changed lines
	Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " Language syntax parsing
	Plug 'nvim-treesitter/nvim-treesitter-textobjects'    " Text-objects based on treesitter
	Plug 'jeetsukumaran/vim-indentwise'                   " Motions over indented blocks
	Plug 'nvim-neotest/nvim-nio'                          " Requirement for nvim-dap-ui
	Plug 'mfussenegger/nvim-dap'                          " Debug adapter protocol
	Plug 'rcarriga/nvim-dap-ui'                           " Frontend for nvim-dap
	Plug 'rmagatti/auto-session'                          " Remote persistence for neovim

	" Language-specific
	Plug 'simrat39/rust-tools.nvim'
	Plug 'vlaadbrain/gnuplot.vim'
	Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && npx --yes yarn install' }

	" Autocomplete
	Plug 'neovim/nvim-lspconfig'
	Plug 'hrsh7th/cmp-nvim-lsp'
	Plug 'hrsh7th/cmp-buffer'
	Plug 'hrsh7th/cmp-path'
	Plug 'hrsh7th/cmp-cmdline'
	Plug 'hrsh7th/nvim-cmp'
call plug#end()

lua << EOF
	-- Completion
	local cmp = require'cmp'
	cmp.setup({
		mapping = cmp.mapping.preset.insert({
			["<C-Space>"] = cmp.mapping.confirm(),
			["<Tab>"] = cmp.mapping.select_next_item(),
			["<S-Tab>"] = cmp.mapping.select_prev_item(),
		}),
		sources = cmp.config.sources({{name='nvim_lsp'}}, {{name='buffer'}}, {{name='path'}})
	})

	-- Use buffer source for `/` and `?` (Doesn't work on enabling `native_menu`).
	cmp.setup.cmdline({'/', '?'}, {
		mapping = cmp.mapping.preset.cmdline(),
		sources = {{name = 'buffer'}}
	})

	-- Use cmdline & path source for ':' (Doesn't work on enabling `native_menu`).
	cmp.setup.cmdline(':', {
		mapping = cmp.mapping.preset.cmdline(),
		sources = cmp.config.sources({{name = 'path'}}, {{name = 'cmdline'}})
	})

	-- Set up lspconfig.
	local lsp = require("lspconfig")
	local capabilities = require('cmp_nvim_lsp').default_capabilities()
	local function lsp_set(name, cmd)
		lsp[name].setup(cmd and {cmd=cmd, capabilities=capabilities} or {capabilities=capabilities})
	end

	lsp_set('rust_analyzer', {'rustup', 'run', 'nightly', 'rust-analyzer'})
	lsp_set('clangd', {'clangd', '--clang-tidy', '--header-insertion=never'})
	lsp_set('pyright')
	lsp_set('lua_ls')

	-- Keybindings and default changes on attaching LSP
	vim.api.nvim_create_autocmd('LspAttach', {
		callback = function(args)
			local client = vim.lsp.get_client_by_id(args.data.client_id)
			local function keymap(mode, key, method, cmd)
				if client.supports_method('textDocument/'..method) then
					vim.keymap.set(mode, key, cmd, {silent=true, buffer=args.buf})
				end
			end

			local function map_to(key, method, cmd)
				keymap('n', '<Leader><Leader>'..key, method, cmd)
			end

			keymap('i', '<C-x>', 'signatureHelp', vim.lsp.buf.signature_help)
			map_to('h', 'signatureHelp', vim.lsp.buf.signature_help)
			map_to('f', 'formatting', vim.lsp.buf.format)
			map_to('r', 'rename', vim.lsp.buf.rename)
			map_to('u', 'references', vim.lsp.buf.references)
			map_to('a', 'codeAction', vim.lsp.buf.code_action)
			map_to('D', 'typeDefinition', vim.lsp.buf.type_definition)
			map_to('i', 'inlayHint', function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(), {bufnr=args.buf})
			end)

			if client.supports_method('textDocument/inlayHint') then
				vim.lsp.inlay_hint.enable(true, {bufnr=args.buf})
			end
		end,
	})

	-- Disable displaying "HINT" diagnostics
	vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
	  vim.lsp.diagnostic.on_publish_diagnostics, {
		virtual_text = {min = vim.diagnostic.severity.INFO},
		signs = {min = vim.diagnostic.severity.INFO},
		underline = true,
		update_in_insert = false,
	  }
	)

	-- Show borders in hover and signature help. Make signature help transient.
	vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, {border='single'})
	vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, {
		border='single',
		focus=false,
		close_events={'CursorMoved', 'CursorMovedI', 'TextChangedI', 'TextChangedP', 'ModeChanged'}
	})

	-- TODO(neovim/16807): Set logfile path in temp, and possibly improve format

	require('lualine').setup{options={theme='nord'}}
	require('gitsigns').setup{
		on_attach=function(bufnr)
			local expr_opts = {buffer=bufnr, silent=true, expr=true, replace_keycodes=false}
			local opts = {buffer=bufnr, silent=true}

			-- Navigation
			vim.keymap.set('', ']c', "&diff ? ']c' : '<cmd>Gitsigns next_hunk<CR>'", expr_opts)
			vim.keymap.set('', '[c', "&diff ? '[c' : '<cmd>Gitsigns prev_hunk<CR>'", expr_opts)

			-- Actions
			vim.keymap.set('n', '<leader>hs', '<cmd>Gitsigns stage_hunk<CR>', opts)
			vim.keymap.set('n', '<leader>hr', '<cmd>Gitsigns reset_hunk<CR>', opts)
			vim.keymap.set('n', '<leader>hu', '<cmd>Gitsigns undo_stage_hunk<CR>', opts)
			vim.keymap.set('n', '<leader>hp', '<cmd>Gitsigns preview_hunk<CR>', opts)
			vim.keymap.set('n', '<leader>tb', '<cmd>Gitsigns toggle_current_line_blame<CR>', opts)
			vim.keymap.set('n', '<leader>td', '<cmd>Gitsigns toggle_deleted<CR>', opts)

			-- Text object
			vim.keymap.set('o', 'ih', ':<C-U>Gitsigns select_hunk<CR>', opts)
			vim.keymap.set('x', 'ih', ':<C-U>Gitsigns select_hunk<CR>', opts)
		end
	}

	require('nvim-treesitter.configs').setup{
		ensure_installed = {"bash", "cpp", "comment", "lua", "python", "rust", "vim", "vimdoc"}, -- Parsers that should always be installed
		auto_install = true,  -- On entering new buffer, install its parser if available
		highlight = {enable = true, additional_vim_regex_highlighting = false},
		incremental_selection = {
			enable = true,
			keymaps = {node_incremental = "/", node_decremental = "?"},
		},
		textobjects = {
			select = {
				enable = true,
				lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
				keymaps = {
					["af"] = "@function.outer", ["if"] = "@function.inner",
					["ac"] = "@class.outer", ["ic"] = "@class.inner",
					["ab"] = "@block.outer", ["ib"] = "@block.inner",
					["au"] = "@call.outer", ["iu"] = "@call.inner",
				},
			},
			lsp_interop = {
				enable = true,
				border = "single",
				peek_definition_code = {
					["<leader>df"] = "@function.outer",
					["<leader>dF"] = "@class.outer",
				},
			},
		},
	}

	dap = require('dap')
	dap.adapters.python = {
		type = 'executable',
		command = vim.g.python3_host_prog,
		args = { '-m', 'debugpy.adapter' },
	}
	dap.configurations.python = {{
		-- nvim-dap options
		type = 'python', -- the type here established the link to the adapter definition: `dap.adapters.python`
		request = 'launch',
		name = "Launch file",
		-- debugpy options, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings
		program = "${file}", -- This configuration will launch the current file if used.
		args = function()
			infile = vim.fn.input('Arguments file: ')
			return infile == '' and {} or vim.fn.readfile(infile)
		end,
		pythonPath = function() return vim.fn.system("which python3"):sub(1, -2) end,
	}}
	
	-- DAP Mappings
	dapui = require("dapui")
	dapui.setup()
	dapmap = {
		c = function() dap.continue() ; dapui.open() end,
		n = dap.step_over,
		s = dap.step_into,
		r = dap.step_out,
		b = dap.toggle_breakpoint,
		R = dap.repl.open,
		w = dapui.toggle,
		l = function() dap.set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end,
		B = function() dap.set_breakpoint(vim.fn.input('Breakpoint condition: ')) end,
		q = function() dap.terminate() ; dapui.close() end,
		-- For tmux-like zooming
		t = ":tab split<CR>",
		T = ":tabclose<CR>",
	}
	for key, val in pairs(dapmap) do
		vim.keymap.set("n", "<BS>"..key, val)
	end

	require('rust-tools').setup()  -- Not used yet, figure out if better conf required
	require("auto-session").setup{log_level = "error"}
EOF

" Shows if folded lines have changed
set foldtext=gitgutter#fold#foldtext()

" Rust running and compiling
au FileType rust noremap <Leader>R :!cargo run<CR>
au FileType rust noremap <Leader>T :!cargo test<CR>
au FileType rust noremap <Leader>C :!cargo clippy<CR>

" Autoformat python (making sure that cursor doesn't jump either during the command or on undo)
au FileType python noremap <Leader><Leader>f :let v=winsaveview() \| exe "normal i \<C-V><BS>" \| exe "%!isort - \| black -q -" \| call winrestview(v) <CR>

" Because default clang-format settings, as well as my zshrc, have 2 spaces
au FileType c,cpp,zsh,yaml set ts=2 | set sw=2 | set expandtab

" Autoformat json
au FileType json noremap <Leader><Leader>f :%!json_pp<CR>

" Colorscheme
" Colorscheme - Editor elements
hi PMenu cterm=none ctermbg=8 ctermfg=none
hi Visual cterm=reverse ctermbg=none ctermfg=none
hi LineNr ctermfg=8
hi DiagnosticError guifg=#ff8888
hi DiagnosticHint ctermfg=7 guifg=NvimLightGrey3

" Colorscheme - Diff
hi DiffDelete ctermbg=1 ctermfg=0 guibg=NvimDarkRed guifg=DarkRed
hi DiffAdd ctermbg=2 ctermfg=0 guibg=NvimDarkGreen guifg=none
hi DiffChange ctermbg=11 ctermfg=0 guibg=NvimDarkYellow guifg=none
hi DiffText ctermbg=3 ctermfg=0 cterm=none guibg=#bb8800 guifg=NvimDarkGrey1

" Colorscheme - Plaintext/identifiers
hi Identifier ctermfg=15 cterm=none guifg=fg gui=none
hi! link Type Identifier
hi! link Constant Identifier
hi! link Function Identifier

" Colorscheme - Particular syntax
hi PreProc ctermfg=10 guifg=NvimLightGreen
hi String ctermfg=13 guifg=LightMagenta
hi Comment ctermfg=3 cterm=italic guifg=#ddaaaa gui=italic

" Colorscheme - Builtins
hi @variable.builtin ctermfg=14 guifg=NvimLightCyan
hi! link @attribute.builtin @variable.builtin
hi! link @constant.builtin @variable.builtin
hi! link @function.builtin @variable.builtin
hi! link @module.builtin @variable.builtin
hi! link @tag.builtin @variable.builtin
hi! link @type.builtin @variable.builtin
hi! link @variable.parameter.builtin @variable.builtin

" Colorscheme - Generic syntax terms
hi Special ctermfg=12 guifg=#aaccff
hi! link Statement Special
hi! link Number Special
hi! link Boolean Special
hi! link Delimiter Special
hi! link Operator Special
hi! link Include Keyword

" Colorscheme - Link treesitter to sane defaults
hi! link @float Float
hi! link @include Include
hi! link @repeat Repeat
hi! link @variable Identifier
hi! link @constructor Function

" Colorscheme - Filetype-specific
hi! link @string.yaml Identifier
