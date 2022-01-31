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
set foldmethod=indent  " Fold according to file indent (Not using syntax because it is slow)
set clipboard+=unnamedplus    " Uses clipboard by default for yank/delete/paste

let mapleader = " "
let g:python3_host_prog = $HOME.'/miniconda3/bin/python'

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
	\})
	try
		execute join(a:000, ' ')
		set winhl=Normal:CursorLine
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
	Plug 'tpope/vim-fugitive'         " Git usage integration
	Plug 'tpope/vim-surround'         " Surrounding with parentheses/HTML-tags etc.
	Plug 'tpope/vim-commentary'       " Commenting out code
	Plug 'tpope/vim-vinegar'          " Browsing files
	Plug 'tpope/vim-repeat'           " Use '.' with vim-surround
	Plug 'nvim-lualine/lualine.nvim'  " Better status line
	Plug 'junegunn/fzf', {'do': './install --all'}  " Fuzzy finder
	Plug 'junegunn/fzf.vim'           " Vim bindings for fzf
	Plug 'neovim/nvim-lspconfig'      " Configs for common (nearly all) langservers
	Plug 'ms-jpq/coq_nvim', {'branch': 'coq'}  " Autocomplete
	Plug 'nvim-lua/plenary.nvim'      " Common functions for neovim
	Plug 'lewis6991/gitsigns.nvim'    " Provides git hunk object and shows if lines changed

	" Language-specific
	Plug 'cespare/vim-toml'
	Plug 'rust-lang/rust.vim'
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

	local function lsp_set(name, cmd)
		lsp[name].setup(coq.lsp_ensure_capabilities{cmd=cmd, on_attach=on_attach})
	end

	lsp_set('rust_analyzer', {'rust_analyzer'})
	lsp_set('clangd', {'clangd', '--clang-tidy', '--header-insertion=never'})
	lsp_set('pylsp', {vim.g.python3_host_prog, '-m', 'pylsp'})
	-- TODO(neovim/16807): Set logfile path in temp, and possibly improve format

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
EOF

" Shows if folded lines have changed
set foldtext=gitgutter#fold#foldtext()

" Rust running and compiling
au FileType rust noremap <Leader>R :!cargo run<CR>
au FileType rust noremap <Leader>t :!cargo test<CR>
au FileType rust noremap <Leader>c :!cargo clippy<CR>

" Because default clang-format settings, as well as my zshrc, have 2 spaces
au FileType c,cpp,zsh,yaml set ts=2 | set sw=2 | set expandtab

" Autoformat json
au FileType json noremap <Leader>f :%!json_pp<CR>

" Beautification
au BufEnter * hi PreProc ctermfg=12
hi PMenu ctermbg=13
hi CursorLine cterm=none ctermbg=8 ctermfg=none
hi Visual ctermbg=none cterm=reverse
hi DiffDelete ctermbg=1 ctermfg=0
hi DiffAdd ctermbg=2 ctermfg=0
hi DiffChange ctermbg=11 ctermfg=0
hi DiffText ctermbg=15 ctermfg=0 cterm=none
hi SpellCap ctermbg=23
