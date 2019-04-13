" Basics
set hidden             " Switch to other buffers even when current is unchanged
set breakindent        " Wrapped part of any line also appears indented
set tabstop=4          " Number of spaces that a <Tab> in the file counts for
set shiftwidth=4       " Number of spaces to use for each step of (auto)indent
set hlsearch           " Highlight the last search results
set relativenumber     " Display every line's number relative to current
set undofile           " Keep an undo file (undo changes after closing)
set number             " If relativenumber is set, shows current line number.
set lazyredraw         " Somehow makes scrolling faster.
set mouse=a            " Enables the use of the mouse like a normal application
set nowrap             " Disables word wrap
set sidescroll=5       " Minimum number of characters to keep on screen
set lcs+=extends:>     " Show marker if line extends beyond screen
set matchpairs+=<:>    " Use '%' to navigate between '<' and '>'
set nofoldenable       " Folds off by default
set foldmethod=indent  " Fold according to file syntax
colorscheme ron 

" Visual movement with the arrows and End-Home 
nnoremap <Down> gj
nnoremap <Up> gk
vnoremap <Down> gj
vnoremap <Up> gk
inoremap <Down> <C-o>gj
inoremap <Up> <C-o>gk
inoremap <Home> <C-o>g<Home>
inoremap <End>  <C-o>g<End>

" Because pageup and pagedown often ruin everything
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
noremap <Leader>h :noh<CR>

" Commands for editing, help, and terminal in new vertical window
command -nargs=? -complete=file E vert new <args>
command -nargs=? -complete=help H vert h <args>
command Term vsplit | term

" Treat <Del> as delete rather than cut
noremap <Del> "_x

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
au FileType text set linebreak

" Moving between windows
noremap <C-h> <C-w>h
noremap <C-j> <C-w>j
noremap <C-k> <C-w>k
noremap <C-l> <C-w>l

" Function to return better text on folds
function FoldFn()
	let lineinfo = "  ".(v:foldend + 1 - v:foldstart)." lines"
	let len = ingo#window#dimensions#NetWindowWidth()-strlen(lineinfo)
	let ftext = getline(v:foldstart)
	return ftext[:len-1].repeat(&fcs[match(&fcs,"fold")+5], len-strlen(ftext)).lineinfo
endfunction

set foldtext=FoldFn()
au ColorScheme * highlight Folded ctermfg=15 ctermbg=17

" Paths of vim configuration files
let $COMMONRC = "~/.config/vim_common.vim"

" For netrw (and hence vinegar)
let g:netrw_bufsettings = 'nomodifiable nomodified readonly nobuflisted nowrap number'

" For Rust plugin
let g:rustc_path = $HOME."/.cargo/bin/rustc"  " Path to rustc
let g:autofmt_autosave = 1                    " Run rustfmt on each save

" For fugitive plugin
set diffopt+=vertical     " Always opens diffs vertically

" For LanguageClient
let g:LanguageClient_autoStart = 1
nnoremap <silent> K :call LanguageClient_textDocument_hover()<CR>
nnoremap <silent> gd :call LanguageClient_textDocument_definition()<CR>
nnoremap <silent> gr :call LanguageClient_textDocument_rename()<CR>
let g:LanguageClient_autoStart = 1
let g:LanguageClient_serverStderr = '/tmp/language_server.stderr'
let g:LanguageClient_settingsPath = $HOME.'/.config/nvim/settings.json'
let c_cpp_ls = ['clangd', '-resource-dir=' . system('clang -print-resource-dir')[:-2]]
let g:LanguageClient_serverCommands = {
	\ 'rust': ['rls'],
	\ 'cpp': c_cpp_ls,
	\ 'c': c_cpp_ls,
	\ 'python': ['pyls', '--log-file', '/tmp/pyls.log']
\ }

" Specify vim-airline theme
let g:airline_theme='papercolor'

" For deoplete (plus autocompleting with tab)
let g:deoplete#enable_at_startup = 1
let g:deoplete#enable_refresh_always = 1
inoremap <expr><Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr><S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" Plugins
call plug#begin('~/.vim_plug')
	" General
	Plug 'Shougo/deoplete.nvim', {'do': ':UpdateRemotePlugins'}  " Asynchronous completion framework
	Plug 'honza/vim-snippets'         " Automatic sections of code to be filled in
	Plug 'Shougo/vimproc.vim'         " Used for ghcmod-vim
	Plug 'tpope/vim-fugitive'         " Git usage integration
	Plug 'tpope/vim-surround'         " Surrounding with parentheses/HTML-tags etc.
	Plug 'scrooloose/nerdcommenter'   " Commenting out code
	Plug 'tpope/vim-vinegar'          " Browsing files
	Plug 'vim-scripts/ingo-library'   " Common functions for vimscript
	Plug 'vim-scripts/IndexedSearch'  " Shows (m out of n matches) for searches
	Plug 'vim-airline/vim-airline'    " Better status line
	Plug 'vim-airline/vim-airline-themes'
	Plug 'junegunn/fzf', {'do': './install --all'}  " Fuzzy finder
	Plug 'autozimu/LanguageClient-neovim', {'branch': 'next', 'do': 'bash install.sh'}

	" Language-specific
	Plug 'eagletmt/neco-ghc'
	Plug 'eagletmt/ghcmod-vim'
	Plug 'Shougo/neco-vim'
	Plug 'rust-lang/rust.vim'
	Plug 'cespare/vim-toml'
	Plug 'vlaadbrain/gnuplot.vim'
call plug#end()

" Filetype-specific formatting mappings
au FileType c,cpp noremap <Leader>f :%!clang-format<CR>
au FileType rust noremap <Leader>f :%!rustfmt<CR>
au FileType python noremap <Leader>f :%!yapf<CR>

" Linting
au FileType haskell noremap <Leader>l :exe '%! hlint - --refactor --refactor-options="--pos '.line('.').','.col('.').'"'<CR>

" Rust running and compiling
au FileType rust noremap <Leader>r :!cargo run<CR>
au FileType rust noremap <Leader>t :!cargo test<CR>
au FileType rust noremap <Leader>c :!cargo clippy<CR>
