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
if isdirectory($HOME.'/miniconda3')
	let g:python3_host_prog = $HOME.'/miniconda3/bin/python'
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
	    \'border': 'rounded',
	\})
	try
		execute join(a:000, ' ')
		set winhl=Normal:PMenu
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
	Plug 'ms-jpq/coq.artifacts', {'branch': 'artifacts'}  " List of snippets
	Plug 'tpope/vim-fugitive'                             " Git usage integration
	Plug 'tpope/vim-surround'                             " Surround with parentheses/HTML-tags etc.
	Plug 'tpope/vim-commentary'                           " Commenting out code
	Plug 'tpope/vim-vinegar'                              " Browsing files
	Plug 'tpope/vim-repeat'                               " Use '.' with vim-surround
	Plug 'nvim-lualine/lualine.nvim'                      " Better status line
	Plug 'junegunn/fzf', {'do': './install --all'}        " Fuzzy finder
	Plug 'junegunn/fzf.vim'                               " Vim bindings for fzf
	Plug 'neovim/nvim-lspconfig'                          " Configs for nearly all langservers
	Plug 'ms-jpq/coq_nvim', {'branch': 'coq'}             " Autocomplete
	Plug 'nvim-lua/plenary.nvim'                          " Common functions for neovim
	Plug 'lewis6991/gitsigns.nvim'                        " hunk object and signs for changed lines
	Plug 'ray-x/lsp_signature.nvim'                       " Show function signature as you type
	Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " Language syntax parsing
	Plug 'nvim-treesitter/nvim-treesitter-textobjects'    " Text-objects based on treesitter
	Plug 'jeetsukumaran/vim-indentwise'                   " Motions over indented blocks
	Plug 'mfussenegger/nvim-dap'                          " Debug adapter protocol
	Plug 'rcarriga/nvim-dap-ui'                           " Frontend for nvim-dap

	" Language-specific
	Plug 'simrat39/rust-tools.nvim'
	Plug 'vlaadbrain/gnuplot.vim'
call plug#end()

lua << EOF
	local function on_attach(client, buf)
		local function map_to(key, cmd)
			local flags = {noremap=true, silent=true}
			vim.api.nvim_buf_set_keymap(buf, 'n', key, '<cmd>lua '..cmd..'()<CR>', flags)
		end

		map_to('K', 'vim.lsp.buf.hover')
		map_to('gd', 'vim.lsp.buf.definition')
		map_to('<Leader>r', 'vim.lsp.buf.rename')
		map_to('<Leader>f', 'vim.lsp.buf.formatting')
		map_to('<Leader>u', 'vim.lsp.buf.references')
		map_to('<Leader>a', 'vim.lsp.buf.code_action')
		map_to('<Leader>D', 'vim.lsp.buf.type_definition')
		map_to('[d', 'vim.diagnostic.goto_prev')
		map_to(']d', 'vim.diagnostic.goto_next')
	end

	vim.g.coq_settings = {
		auto_start='shut-up',
		limits={completion_auto_timeout=0.3},
		keymap={jump_to_mark='<c-right>'},
		clients={lsp={weight_adjust=2.0}, snippets={weight_adjust=1.0}}
	}
	local lsp = require("lspconfig")
	local coq = require("coq")

	local function lsp_set(name, cmd, options)
		lsp[name].setup(coq.lsp_ensure_capabilities{cmd=cmd, on_attach=on_attach, settings=options})
	end

	lsp_set('rust_analyzer', {'rustup', 'run', 'nightly', 'rust-analyzer'}, {})
	lsp_set('clangd', {'clangd', '--clang-tidy', '--header-insertion=never'}, {})
	pylsp_settings = {
		plugins={flake8={enabled=true}, pyflakes={enabled=false}, pycodestyle={enabled=false}},
		configurationSources={'flake8'}
	}
	lsp_set('pylsp', {vim.g.python3_host_prog, '-m', 'pylsp'}, {pylsp=pylsp_settings})
	-- TODO(neovim/16807): Set logfile path in temp, and possibly improve format

	require('lsp_signature').setup{toggle_key="<C-x>"}
	require('lualine').setup{options={theme='nord'}}
	require('gitsigns').setup{
		on_attach=function(bufnr)
			local function map(mode, lhs, rhs, opts)
				opts = vim.tbl_extend('force', {noremap = true, silent = true}, opts or {})
				vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, opts)
			end

			-- Navigation
			map('', ']c', "&diff ? ']c' : '<cmd>Gitsigns next_hunk<CR>'", {expr=true})
			map('', '[c', "&diff ? '[c' : '<cmd>Gitsigns prev_hunk<CR>'", {expr=true})

			-- Actions
			map('n', '<leader>hs', '<cmd>Gitsigns stage_hunk<CR>')
			map('n', '<leader>hr', '<cmd>Gitsigns reset_hunk<CR>')
			map('n', '<leader>hu', '<cmd>Gitsigns undo_stage_hunk<CR>')
			map('n', '<leader>hp', '<cmd>Gitsigns preview_hunk<CR>')
			map('n', '<leader>tb', '<cmd>Gitsigns toggle_current_line_blame<CR>')
			map('n', '<leader>td', '<cmd>Gitsigns toggle_deleted<CR>')

			-- Text object
			map('o', 'ih', ':<C-U>Gitsigns select_hunk<CR>')
			map('x', 'ih', ':<C-U>Gitsigns select_hunk<CR>')
		end
	}

	require('nvim-treesitter.configs').setup{
		ensure_installed = "all", -- A list of parser names, or "all"
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
				border = "rounded",
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
EOF

" Shows if folded lines have changed
set foldtext=gitgutter#fold#foldtext()

" Rust running and compiling
au FileType rust noremap <Leader>R :!cargo run<CR>
au FileType rust noremap <Leader>T :!cargo test<CR>
au FileType rust noremap <Leader>C :!cargo clippy<CR>

" Because default clang-format settings, as well as my zshrc, have 2 spaces
au FileType c,cpp,zsh,yaml set ts=2 | set sw=2 | set expandtab

" Autoformat json
au FileType json noremap <Leader>f :%!json_pp<CR>

" Beautification
hi PMenu cterm=none ctermbg=8 ctermfg=none
hi MatchParen cterm=underline ctermbg=none ctermfg=none
hi Visual ctermbg=none cterm=reverse
hi DiffDelete ctermbg=1 ctermfg=0
hi DiffAdd ctermbg=2 ctermfg=0
hi DiffChange ctermbg=11 ctermfg=0
hi DiffText ctermbg=15 ctermfg=0 cterm=none
hi SpellCap ctermbg=23
hi link FloatBorder PMenu

hi PreProc ctermfg=10
hi Include ctermfg=10 cterm=italic
hi link Define Include
hi link TSNamespace PreProc
hi Macro ctermfg=10 cterm=bold
hi Identifier ctermfg=none ctermbg=none cterm=none
hi TSVariable ctermfg=15
hi TSVariableBuiltin cterm=italic
hi Function ctermfg=14 cterm=none
hi TSFuncBuiltin ctermfg=14 cterm=italic
hi Type ctermfg=12
hi link TSConstructor Function
hi TSLiteral ctermfg=13
hi! link String TSLiteral
hi! link Number TSLiteral
hi Constant ctermfg=7
hi TSConstBuiltin ctermfg=7 cterm=italic
hi Comment ctermfg=9 cterm=italic
hi Special ctermfg=3
hi link yamlTSField TSLabel  " Consistent with JSON
hi yamlTSString ctermfg=15
