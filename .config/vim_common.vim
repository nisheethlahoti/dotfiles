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
set foldmethod=syntax  " Fold according to file syntax
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
		%!xxd -r
		set binary
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

" For ale plugin
let g:ale_linters = {'rust': ['cargo'], 'cpp': [], 'c': []}
nnoremap <A-j> :ALENextWrap<CR>
nnoremap <A-k> :ALEPreviousWrap<CR>

" For Rust plugin
let g:rustc_path = $HOME."/.cargo/bin/rustc"  " Path to rustc
let g:autofmt_autosave = 1                    " Run rustfmt on each save

" For fugitive plugin
set diffopt+=vertical     " Always opens diffs vertically

" Goto Definition/declaration/include/whatever
nnoremap gd :YcmCompleter GoTo<CR>

" Specify vim-airline theme
let g:airline_theme='papercolor'

" Plugins
call plug#begin('~/.vim/plugged')
	" General
	Plug 'valloric/YouCompleteMe'     " Code completion + GoTo def + checking
	Plug 'honza/vim-snippets'         " Automatic sections of code to be filled in
	Plug 'w0rp/ale'                   " Linting.
	Plug 'Shougo/vimproc.vim'         " Used for ghcmod-vim
	Plug 'tpope/vim-fugitive'         " Git usage integration
	Plug 'tpope/vim-surround'         " Surrounding with parentheses/HTML-tags etc.
	Plug 'scrooloose/nerdcommenter'   " Commenting out code
	Plug 'vim-scripts/ingo-library'   " Common functions for vimscript
	Plug 'vim-scripts/IndexedSearch'  " Shows (m out of n matches) for searches
	Plug 'vim-airline/vim-airline'    " Better status line
	Plug 'vim-airline/vim-airline-themes'

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
au FileType rust noremap <Leader>f :RustFmt<CR>

" Linting
au FileType c,cpp noremap <Leader>l :YcmCompleter FixIt<CR>
au FileType haskell noremap <Leader>l :exe '%! hlint - --refactor --refactor-options="--pos '.line('.').','.col('.').'"'<CR>

" Rust running and compiling
au FileType rust noremap <Leader>r :!cargo run<CR>
au FileType rust noremap <Leader>t :!cargo test<CR>
au FileType rust noremap <Leader>b :!cargo build<CR>
