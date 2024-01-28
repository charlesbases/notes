#!/usr/bin/env bash

set -e

repo=$HOME/.remote

help() {
  echo """\
usage:
  ./$(basename $0) [options]

options:
  -h help
  -i identity_file
  -v vim remote file
  -a show remote list"""
  exit
}

index=0
display() {
  local limit=0
  while read line; do
    args=($line)
    if [[ $limit -lt $[${#args[0]}+${#args[1]}] ]]; then
      limit=$[${#args[0]}+${#args[1]}+3]
    fi
  done <<< $(grep -v '^#\|^$' $repo)

  while read line; do
    index=$[index+1]

    args=($line)
    echo -e "$index. \033[32m${args[0]}\033[0m\033[34m <${args[1]}>\033[0m \c "
    for (( i = 0; i < $[$limit-${#args[0]}-${#args[1]}]; i++ )); do
      echo -n "·"
    done
    if [[ -n ${args[4]} ]]; then
      echo " ${args[4]}"
    else
      echo " <none>"
    fi
  done <<< $(grep -v '^#\|^$' $repo)
}

connect() {
  read -sp ">: " input

  if [[ "$input" -lt 1 ]] || [[ "$input" -gt $index ]] ; then
    echo -e "\033[31mmust be 1 - $index\033[0m"
    exit
  fi

  args=($(grep -m $input -v '^#\|^$' $repo | tail -n 1))
  ip=${args[0]}
  user=${args[1]}
  passwd=${args[2]}
  bastion=${args[3]}

  echo -e "\033[31m$user@$ip\033[0m"

  # sshpass
  #if [[ -n $(command -v sshpass) ]]; then
  #  sshpass -p $passwd ssh $user@$ip
  #fi

  # ssh-copy-id
  if [[ -n "$identity" ]]; then
    ssh-copy-id -i $identity $user@$ip
  fi

  # direct
  if [[ "$bastion" == "direct" ]]; then
    ssh $user@$ip
  else
    ssh -t $bastion "ssh $user@$ip"
  fi
}

main() {
  display
  connect
}

# ssh-copy-id
identity=""

if [[ ! -f $repo ]]; then
  cat > $repo << EOF
# IP           User  Passwd  Bastion           Remark
# 192.168.6.9  user  passwd  direct            direct connect server
# 192.168.9.6  user  passwd  user@192.168.6.9  bastion host connect

EOF
fi

while getopts ":h:i:av" opt; do
  case $opt in
    h)
    echo $OPTARG
    ;;
    i)
    if [[ ! -f "$OPTARG" ]]; then
      echo -e "\033[31mInvalid identity_file. No such file or directory\033[0m"
      exit
    fi
    identity=$OPTARG
    ;;
    v)
    vim $repo
    exit
    ;;
    a)
    display
    exit
    ;;
    ?) # 其他参数
    help
    ;;
  esac
done

#shift $(($OPTIND - 1))

main
