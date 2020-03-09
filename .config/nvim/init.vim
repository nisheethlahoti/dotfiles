" Basics
set hidden             " Switch to other buffers even when current has been changed
set breakindent        " Wrapped part of any line also appears indented
set linebreak          " When wrapping text, break on word boundaries
set tabstop=4          " Number of spaces that a <Tab> in the file counts for
set shiftwidth=4       " Number of spaces to use for each step of (auto)indent
set hlsearch           " Highlight the last search results
set incsearch          " Incrementally advance cursor position while searching
set inccommand=split   " Shows the effects of a command incrementally, as you type.
set relativenumber     " Display every line's number relative to current
set undofile           " Keep an undo file (undo changes after closing)
set number             " If relativenumber is set, shows current line number.
set lazyredraw         " Somehow makes scrolling faster.
set mouse=a            " Enables the use of the mouse like a normal application
set nowrap             " Disables word wrap
set scrolloff=5        " Minimal number of screen lines to keep around the cursor
set sidescroll=5       " Minimum number of characters to keep on screen
set lcs+=extends:>     " Show marker if line extends beyond screen
set matchpairs+=<:>    " Use '%' to navigate between '<' and '>'
set nofoldenable       " Folds off by default
set foldmethod=indent  " Fold according to file indent (Not using syntax because it is slow)
set clipboard+=unnamedplus    " Uses clipboard by default for yank/delete/paste

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
command Q q
command Wq wq

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

" Paths of vim configuration file
let $NVIMRC = "~/.config/nvim/init.vim"

" For netrw (and hence vinegar)
let g:netrw_bufsettings = 'nomodifiable nomodified readonly nobuflisted nowrap number'

" For fugitive plugin
set diffopt+=vertical     " Always opens diffs vertically

" For fzf plugin (\o for opening file and \g for searching through files)
noremap <Leader>o :Files<CR>
noremap <Leader>l :Lines<CR>
noremap <Leader>h :History:<CR>
command! -bang -nargs=* Files call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)
command! -bang -nargs=* -complete=file Lines call fzf#vim#grep(
	\ 'rg --line-number --no-heading --color=always "" '.<q-args>, 1,
	\ fzf#vim#with_preview(), <bang>0)
let g:fzf_layout = {'window': {'width': 0.8, 'height': 0.8, 'relative': 'editor'}}

" For LanguageClient
function LanguageClientMaps()
	nnoremap <silent> K :call LanguageClient_textDocument_hover()<CR>
	nnoremap <silent> gd :call LanguageClient_textDocument_definition()<CR>
	nnoremap <silent> <Leader>r :call LanguageClient_textDocument_rename()<CR>
	nnoremap <silent> <Leader>f :call LanguageClient_textDocument_formatting()<CR>
	nnoremap <silent> <Leader>u :call LanguageClient_textDocument_references()<CR>
endfunction

let g:LanguageClient_autoStart = 1
let g:LanguageClient_hasSnippetSupport = 1
let g:LanguageClient_serverStderr = '/tmp/language_server.stderr'
let c_cpp_ls = ['clangd', '--clang-tidy', '--header-insertion=never']
let g:LanguageClient_serverCommands = {'rust': ['rls'], 'cpp': c_cpp_ls, 'c': c_cpp_ls, 'python': ['pyls']}
let s:lc_filetypes=join(keys(g:LanguageClient_serverCommands), ',')
execute 'au FileType '.s:lc_filetypes.' call LanguageClientMaps()'

" Mappings for ncm2 and ultisnips
let g:deoplete#enable_at_startup = 1
let g:deoplete#enable_refresh_always = 1
au BufEnter * call deoplete#custom#source("ultisnips", "rank", 9999)  " Set highest priority for snippets
let g:UltiSnipsExpandTrigger = "<C-Space>"
let g:UltiSnipsJumpForwardTrigger = "<C-Right>"
let g:UltiSnipsJumpBackwardTrigger = "<C-Left>"

" Use <Tab> and <S-Tab> keys for autocomplete
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" Plugins
call plug#begin('~/.plugins/neovim')
	" General
	Plug 'SirVer/ultisnips'           " Snippet manager
	Plug 'honza/vim-snippets'         " List of snippets
	Plug 'tpope/vim-fugitive'         " Git usage integration
	Plug 'tpope/vim-surround'         " Surrounding with parentheses/HTML-tags etc.
	Plug 'scrooloose/nerdcommenter'   " Commenting out code
	Plug 'tpope/vim-vinegar'          " Browsing files
	Plug 'vim-scripts/ingo-library'   " Common functions for vimscript
	Plug 'vim-scripts/IndexedSearch'  " Shows (m out of n matches) for searches
	Plug 'vim-airline/vim-airline'    " Better status line
	Plug 'vim-airline/vim-airline-themes'
	Plug 'junegunn/fzf', {'do': './install --all'}  " Fuzzy finder
	Plug 'junegunn/fzf.vim'           " Vim bindings for fzf
	Plug 'autozimu/LanguageClient-neovim', {'branch': 'next', 'do': 'bash install.sh'}
	Plug 'Shougo/deoplete.nvim', {'do': ':UpdateRemotePlugins'}  " Asynchronous completion framework

	" Language-specific
	Plug 'Shougo/neco-syntax'
	Plug 'Shougo/neco-vim'
	Plug 'cespare/vim-toml'
	Plug 'rust-lang/rust.vim'
	Plug 'vlaadbrain/gnuplot.vim'
call plug#end()

" Rust running and compiling
au FileType rust noremap <Leader>r :!cargo run<CR>
au FileType rust noremap <Leader>t :!cargo test<CR>
au FileType rust noremap <Leader>c :!cargo clippy<CR>

" Because default clang-format settings have 2 spaces
au FileType c,cpp set tabstop=2
au FileType c,cpp set shiftwidth=2

" Beautification
let g:airline_theme='base16'
au BufEnter * hi PreProc ctermfg=12
hi PMenu ctermbg=13
hi CursorLine cterm=none ctermbg=8 ctermfg=none
hi Visual ctermbg=4 cterm=reverse
hi DiffDelete ctermbg=1 ctermfg=0
hi DiffAdd ctermbg=2 ctermfg=0
hi DiffChange ctermbg=11 ctermfg=0
hi DiffText ctermbg=15 ctermfg=0 cterm=none
