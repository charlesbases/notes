#!/usr/bin/env bash

if test -z "$WINELOADERNOEXEC"
then
  GIT_EXEC_PATH="$(git --exec-path 2>/dev/null)"
  COMPLETION_PATH="${GIT_EXEC_PATH%/libexec/git-core}"
  COMPLETION_PATH="${COMPLETION_PATH%/lib/git-core}"
  COMPLETION_PATH="$COMPLETION_PATH/share/git/completion"

  if test -f "$COMPLETION_PATH/git-prompt.sh"
  then
    . "$COMPLETION_PATH/git-completion.bash"
  fi
fi

__git_branch() {
  local branch=$(git branch 2>/dev/null | grep '*' | sed 's/^* //g')

  if test -n "$branch"
  then
    echo -e "\033[36m($branch)\033[0m"
  fi
}

# color: blue
PS1='\n\[\033[34m\]#\[\033[0m\] '
# user. color: cyan
PS1="$PS1"'\[\033[36m\]\u\[\033[0m\]'
# '@'
PS1="$PS1"' @ '
# hostname. color: green
PS1="$PS1"'\[\033[32m\]charlesbases\[\033[0m\]'
# 'in'
PS1="$PS1"' in '
# $pwd. color: yellow
PS1="$PS1"'\[\033[33m\]\w\[\033[0m\]'
# time
PS1="$PS1"' [\t] '
# git-branch
PS1="$PS1"'`__git_branch`'
# '$'
PS1="$PS1"'\n\[\033[31m\]$\[\033[0m\] '

MSYS2_PS1="$PS1"
