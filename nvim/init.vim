" ==============================================================================
" General config

source ~/.config/nvim/vimplug.vim

set termguicolors

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
set path+=ui,src,zucchini/src,.

" Stop neovim saving things like registers between restarts.
set shada=


" ==============================================================================
" Key bindings

let mapleader=","

nnoremap <Leader>s :wa<CR>

" Reselect the visual area when changing indenting in visual mode.
vnoremap < <gv
vnoremap > >gv

" Control the Quickfix window.
nnoremap <C-Q>o :botright copen<CR>
nnoremap <C-Q><C-O> :botright copen<CR>
nnoremap <C-Q>c :cclose<CR>
nnoremap <C-Q><C-C> :cclose<CR>


" ==============================================================================
" Plugin Config

" ctrlp
let g:ctrlp_custom_ignore = 'node_modules\|bower_components\|DS_Store\|git'
let g:ctrlp_working_path_mode = 'a'
let g:ctrlp_by_filename = 1

nnoremap <silent> <Leader>b :CtrlPBuffer<CR>
nnoremap <silent> <Leader>n :NERDTreeFocus<CR>
nnoremap <silent> <Leader>r :NERDTreeFind<CR>

" vim-tmux-navigator
let g:tmux_navigator_command = $TMUX_COMMAND

if has('nvim')
  nnoremap <silent> <BS> :TmuxNavigateLeft<CR>
endif

" vim-test
" let test#strategy = "neoterm"
" nnoremap <Leader>t :wa<CR>:TestFile<CR>

" vim-jsx
let g:jsx_ext_required = 0  " Treat .js files as JSX

" ale
let g:ale_lint_on_text_changed = 'normal'
let g:ale_lint_on_insert_leave = 1
let g:ale_linters = { 'javascript': ['standard'] }
let g:ale_javascript_standard_use_global = 1
let g:ale_warn_about_trailing_whitespace = 0
let g:ale_sign_error = '✘'
let g:ale_sign_warning = '?'

" NERDTree
let NERDTreeMinimalUI=1
let NERDTreeShowLineNumbers=1
let NERDTreeWinSize=48
let NERDTreeSortOrder=[]

" ==============================================================================
" Autocmds

augroup vimrcCommands
autocmd!

" Remove whitespace at the end of lines on save.
" See http://vim.wikia.com/wiki/Remove_unwanted_spaces#Automatically_removing_all_trailing_whitespace
autocmd BufWritePre * :%s/\s\+$//e

autocmd FocusGained * highlight StatusLine guifg=#22aa33
autocmd FocusLost * highlight StatusLine guifg=#555555

autocmd InsertEnter * highlight StatusLine guifg=#2233aa
autocmd InsertLeave * highlight StatusLine guifg=#22aa33

autocmd FileType go setlocal ts=8 sw=8 noexpandtab

augroup END


" ==============================================================================
" Colors

colorscheme Tomorrow-Night-Bright

" Highlight the active window more brightly:
highlight StatusLine guifg=#2233aa guibg=white
set fillchars+=vert:\  " That space after the \ is significant.
