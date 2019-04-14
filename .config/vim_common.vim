" Basics
set hidden             " Switch to other buffers even when current has been changed
set breakindent        " Wrapped part of any line also appears indented
set linebreak          " When wrapping text, break on word boundaries
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
set foldmethod=indent  " Fold according to file indent (Not using syntax because it is slow)
behave mswin           " Behaves like graphical editors in select-mode
set selectmode=""      " But enter visual mode instead of select mode with mouse selection
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

" For fugitive plugin
set diffopt+=vertical     " Always opens diffs vertically

" For LanguageClient
nnoremap <silent> K :call LanguageClient_textDocument_hover()<CR>
nnoremap <silent> gd :call LanguageClient_textDocument_definition()<CR>
nnoremap <silent> gr :call LanguageClient_textDocument_rename()<CR>
let g:LanguageClient_autoStart = 1
let g:LanguageClient_hasSnippetSupport = 1
let g:LanguageClient_serverStderr = '/tmp/language_server.stderr'
let c_cpp_ls = ['clangd', '-resource-dir=' . system('clang -print-resource-dir')[:-2]]
let g:LanguageClient_serverCommands = {'rust': ['rls'], 'cpp': c_cpp_ls, 'c': c_cpp_ls, 'python': ['pyls']}

" Specify vim-airline theme
let g:airline_theme='papercolor'

" Functions for ncm2 and ultisnips
func! CommonPrefix(words) abort  " Longest common prefix for list of strings. Aborts on empty list.
	let base = a:words[0]
	for prefix_len in range(len(base))
		for word in a:words[1:]
			if word[prefix_len] != base[prefix_len]
				return base[:prefix_len][:-2]
			endif
		endfor
	endfor
	return base
endfunction

" If no dropdown list visible, returns a:keys. Else expands to common prefix
" of list, if said prefix is longer than the sequence already typed.
func! Ncm2ExpandCommonOr(keys)
	if !pumvisible()
		return a:keys
	endif

	let typedlen = col('.') - ncm2#_s('startbcol')
	let common = CommonPrefix(map(ncm2#_s('matches'), 'v:val.word'))
	return typedlen < len(common) ? repeat("\<C-h>", typedlen) . common : ""
endfunction

au BufEnter * call ncm2#enable_for_buffer()
au BufEnter * call ncm2#override_source('ultisnips', {'priority': 10})
set completeopt=noinsert,menuone,noselect
imap <silent><expr><CR> ncm2_ultisnips#expand_or(Ncm2ExpandCommonOr("<CR>"), 'n')
let g:UltiSnipsExpandTrigger = "<Plug>(DONTUSE_ULTISNIPS_EXPAND)"
let g:UltiSnipsJumpForwardTrigger = "<Tab>"
let g:UltiSnipsJumpBackwardTrigger = "<S-Tab>"

" Plugins
call plug#begin('~/.vim_plug')
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
	Plug 'autozimu/LanguageClient-neovim', {'branch': 'next', 'do': 'bash install.sh'}
	Plug 'ncm2/ncm2'                  " Autocomplete
	Plug 'ncm2/ncm2-ultisnips'        " Support of ultisnips with ncm2
	Plug 'ncm2/ncm2-bufword'          " Adds words from current buffer to ncm2
	Plug 'roxma/nvim-yarp'            " Dependency of ncm-2

	" Language-specific
	Plug 'ncm2/ncm2-syntax' | Plug 'Shougo/neco-syntax'
	Plug 'ncm2/ncm2-vim' | Plug 'Shougo/neco-vim'
	Plug 'cespare/vim-toml'
	Plug 'vlaadbrain/gnuplot.vim'
call plug#end()

" Filetype-specific formatting mappings
au FileType c,cpp noremap <Leader>f :%!clang-format<CR>
au FileType rust noremap <Leader>f :%!rustfmt<CR>
au FileType python noremap <Leader>f :%!yapf<CR>

" Rust running and compiling
au FileType rust noremap <Leader>r :!cargo run<CR>
au FileType rust noremap <Leader>t :!cargo test<CR>
au FileType rust noremap <Leader>c :!cargo clippy<CR>
