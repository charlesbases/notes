vim ～/.vimrc

···
syntax on
filetype on

set go=
set nocompatible
set term=builtin_ansi

set encoding=utf-8
set fileencoding=utf-8
set fileencodings=ucs-bom,utf-8,gbk,gb2312,cp936,big5,gb18030,shift-jis,euc-jp,euc-kr,latin1

set nobomb                   " 不自动设置字节序标记
set nobackup                 " 禁用备份
set noswapfile               " 禁用 swp 文件
set clipboard=unnamed        " 共享剪贴板
set fileformats=unix,dos     " 换行符
set ruler                    " 打开状态栏标尺
set cursorline               " 突出显示当前行
set syntax=on                " 语法高亮
set confirm                  " 在处理未保存或只读文件的时候，弹出确认
set ignorecase               " 搜索忽略大小写
set cmdheight=2              " 命令行高度
set background=dark          " 黑色背景
set autoread                 " 自动加载文件改动
set noautoindent             " 关闭自动缩进
set pastetoggle=<F12>        " 开关
set expandtab                " 替换 Tab
set tabstop=2                " Tab键的宽度

set showmatch                " 高亮显示匹配的括号
set matchtime=1              " 匹配括号高亮的时间

set t_Co=256                 " 颜色

colorscheme pablo

" 默认以双字节处理那些特殊字符
if v:lang =~? '^\(zh\)\|\(ja\)\|\(ko\)'
	set ambiwidth=double
endif

" 清空整页
map zz ggdG
" 开始新行
map <cr> o<esc>
" 注释该行
map / 0i# <esc>j0
" 取消注释
map \ 0xx <esc>j0
···
