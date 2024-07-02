#!/usr/bin/env bash

os_type=

linux_setting() {
  echo "unrealized"
  exit
}

macos_setting() {
  echo "unrealized"
  exit
}

windwos_setting() {
#  git_dir="$EXEPATH/.."
#  git_etc_dir="$git_dir/etc"
  git_etc_dir="/etc"
  git_etc_profile_dir="$git_etc_dir/profile.d"

  git_config_path="$HOME/.gitconfig"
  git_bashrc_path="$git_etc_dir/bash.bashrc"
  git_inputrc_path="$git_etc_dir/inputrc"

  # gitconfig
  if test -f "../gitconfig"; then
    echo -e "\033[32mgitconfig\033[0m"

    cat "../gitconfig" > "$git_config_path"
  fi

  # git-prompt.sh
  if test -f "git-prompt.sh"; then
    echo -e "\033[32mgit-prompt.sh\033[0m"

    cat "git-prompt.sh" > "$git_etc_profile_dir/git-prompt.sh"
  fi

  # inputrc
  if test -z "$(grep -o -- 'Modify by' $git_inputrc_path)"; then
    echo -e "\033[32minputrc\033[0m"

    #  删除键闪屏
    sed -i -s 's/set bell-style visible/set bell-style none/g' "$git_inputrc_path"
    #  历史记录前缀搜索
    cat >> $git_inputrc_path << EOF

# Modify by $(date +%Y-%m-%dT%H:%M:%S)

"\e[A": history-search-backward
"\e[B": history-search-forward
EOF
  fi

  # bash.bashrc
  if test -z "$(grep -o -- 'Modify by' $git_bashrc_path)"; then
    echo -e "\033[32mbash.bashrc\033[0m"

    cat >> $git_bashrc_path << EOF

# Modify by $(date +%Y-%m-%dT%H:%M:%S)

# session history
PROMPT_COMMAND='history -a'

# environment

# alias
alias l='ls -alh'
alias la='ls -alh'
alias cs='cd "\$GOPATH\src"'
alias open='start "" '

alias goland='start "D:\JetBrains\GoLand\bin\goland64.exe" '

alias proxy='export https_proxy=http://127.0.0.1:33210 http_proxy=http://127.0.0.1:33210 all_proxy=socks5://127.0.0.1:33211'
EOF
  fi
}

if test $(uname | grep -o 'Linux'); then
  linux_setting
elif test $(uname | grep -o 'Darwin'); then
  macos_setting
elif test $(uname | grep -o 'MINGW64_NT'); then
  windwos_setting
else
  echo "unsupported os of \"$(uname)\""
  exit
fi
