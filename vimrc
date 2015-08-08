" ==============================================================================
" Configuration

source ~/.vundle

set autoindent
set nosmartindent
set nocindent
set backspace=indent,eol,start
set autoread
set autowriteall
set dir=/tmp
set expandtab
set hidden
set incsearch
set laststatus=2
set statusline=%f\ %h%m%r%=%l/%L
set wildmode=list:longest
set mouse=a
set ttimeoutlen=0 " Don't hang around after hitting escape in command mode.

syntax enable

let g:ctrlp_custom_ignore = 'node_modules\|bower_components\|DS_Store\|git'
let g:turbux_command_prefix = 'bundle exec'
let g:tmux_navigator_command = $TMUX_COMMAND


" ==============================================================================
" Key bindings

let mapleader=","

noremap <Leader>b :LustyBufferExplorer<CR>
noremap <Leader>f :LustyFilesystemExplorer<CR>
noremap <Leader>r :LustyFilesystemExplorerFromHere<CR>
noremap <Leader>w :wa<CR>

noremap <Leader>ah :Tab /=><CR>

" Close all other windows, and open the alternate file for the current window
" in a vertical split:
noremap <Leader>o <C-W>o:AV<CR>

" Reselect the visual area when changing indenting in visual mode.
vnoremap < <gv
vnoremap > >gv


" ==============================================================================
" Filetype settings

filetype plugin on
filetype indent off

augroup vimrcCommands
autocmd!

" Without this, .md files are treated as Modula-2!
autocmd BufRead,BufNewFile *.md  set filetype=markdown

autocmd FileType ruby       setlocal ts=2 sw=2 sts=2
autocmd FileType eruby      setlocal ts=2 sw=2 sts=2
autocmd FileType vim        setlocal ts=2 sw=2 sts=2
autocmd FileType markdown   setlocal ts=4 sw=4 sts=4 linebreak
autocmd FileType puppet     setlocal ts=2 sw=2 sts=2
autocmd FileType html       setlocal ts=2 sw=2 sts=2
autocmd FileType javascript setlocal ts=2 sw=2 sts=2

" Helpful task list management in markdown files:
autocmd FileType markdown noremap <buffer> <Leader>tn o- [ ]<space>
autocmd FileType markdown noremap <buffer> <Leader>td :.s/\[ \]/\[x\]/<CR>

" Remove whitespace at the end of lines on save.
" See http://vim.wikia.com/wiki/Remove_unwanted_spaces#Automatically_removing_all_trailing_whitespace
autocmd BufWritePre * :%s/\s\+$//e

autocmd BufWritePost .vimrc source $MYVIMRC
autocmd BufWritePost .vundle source $MYVIMRC

augroup END


" ==============================================================================
" GUI settings

colorscheme grb256

" Make the statusline readable.
highlight StatusLineNC guibg=#222222 guifg=#666666

if has("gui_macvim")
  set background=dark
  set gfn=Inconsolata:h14
  set linespace=1

  " Hide the scrollbars.
  set guioptions-=L
  set guioptions-=r
end
