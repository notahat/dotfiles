" ==============================================================================
" General config

source ~/.config/nvim/vimplug.vim

set statusline=%f\ %h%m%r%=%l/%L

set tabstop=2 shiftwidth=2 softtabstop=2
filetype indent off
set expandtab
set breakindent

set nofoldenable

set relativenumber
set cursorline

set wildmode=list:longest

set incsearch
set inccommand=split

set showcmd
set belloff=esc

set mouse=a

set hidden

" This is so gf will find files in the Sites app properly.
set path+=ui,.


" ==============================================================================
" Key bindings

let mapleader=","

nnoremap <Leader>s :wa<CR>

" Better split management
nnoremap <Leader>- :sp<CR>
nnoremap <Leader>\ :vs<CR>
nnoremap <Leader>x <C-W>c
nnoremap <Leader>o <C-W>o

" Reselect the visual area when changing indenting in visual mode.
vnoremap < <gv
vnoremap > >gv


" ==============================================================================
" Plugin Config

" ctrlp
let g:ctrlp_custom_ignore = 'node_modules\|bower_components\|DS_Store\|git'
let g:ctrlp_working_path_mode = 'c'
let g:ctrlp_cmd = 'CtrlPRoot'
let g:ctrlp_by_filename = 1

nnoremap <silent> <Leader>b :CtrlPBuffer<CR>
nnoremap <silent> <Leader>r :CtrlP<CR>

" vim-tmux-navigator
let g:tmux_navigator_command = $TMUX_COMMAND

if has('nvim')
  nnoremap <silent> <BS> :TmuxNavigateLeft<CR>
endif

" vim-test
let test#strategy = "neoterm"

nnoremap <Leader>t :wa<CR>:TestFile<CR>

" vim-jsx
let g:jsx_ext_required = 0  " Treat .js files as JSX

" ale
let g:ale_linters = { 'javascript': ['standard'] }
" Use the globally installed version of standard, not the one in node_modules.
let g:ale_javascript_standard_use_global=1

" ==============================================================================
" Autocmds

augroup vimrcCommands
autocmd!

" Remove whitespace at the end of lines on save.
" See http://vim.wikia.com/wiki/Remove_unwanted_spaces#Automatically_removing_all_trailing_whitespace
autocmd BufWritePre * :%s/\s\+$//e

autocmd FocusGained * highlight StatusLine ctermfg=35
autocmd FocusLost * highlight StatusLine ctermfg=59

autocmd InsertEnter * highlight StatusLine ctermfg=111
autocmd InsertLeave * highlight StatusLine ctermfg=29

augroup END


" ==============================================================================
" Colors

colorscheme Tomorrow-Night-Bright

" Highlight the active window more brightly:
highlight StatusLine ctermfg=29
highlight StatusLine ctermbg=white
