source $HOME/.config/vim_common.vim

set scrolloff=5          " Minimal number of screen lines to keep around the cursor 
set incsearch            " Incrementally advance cursor position while searching
set inccommand=split     " Shows the effects of a command incrementally, as you type.

let $NVIMRC = "~/.config/nvim/init.vim"

" See the difference between the current buffer and the file it has been loaded from
command DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis
               \ | wincmd p | diffthis

" Moving between windows, and escaping terminal
tnoremap <C-h> <C-\><C-n><C-w>h
tnoremap <C-j> <C-\><C-n><C-w>j
tnoremap <C-k> <C-\><C-n><C-w>k
tnoremap <C-l> <C-\><C-n><C-w>l
tnoremap <C-t> <C-\><C-n>gt
