source $VIMRUNTIME/defaults.vim
source $HOME/.config/vim_common.vim

let $VIMRC = "~/.vimrc"

" Because vim, unlike neovim, doesn't have inccommand
nnoremap S :%s//
vnoremap S :s//
