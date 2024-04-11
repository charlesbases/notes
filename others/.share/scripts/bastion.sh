#!/usr/bin/env bash

set -e

repofile=$HOME/.remote

help() {
  echo """\
usage:
  ./$(basename $0) [options]

options:
  -h help
  -i add identity_file
  -v vim args file
  -p show password"""
  exit
}

display() {
  local count=
  if [[ -z $show_password ]]; then
    # hide password
    count=$[$(awk '!/^#/ && NF>0 {print length($1 $2)}' $repofile | sort -r | head -1) + 3]
    awk -v total=$count '!/^#/ && NF>0 {seq++; n = total - length($1 $2); printf "%d. \033[32m%s\033[0m \033[34m%s\033[0m ", seq, $1, $2; for (i=1;i<=n;i++) printf "."; printf " "; print ($5 != "") ? substr($0, index($0, $5)) : "<none>"}' $repofile
  else
    # show password
    count=$[$(awk '!/^#/ && NF>0 {print length($1 $2 $3)}' $repofile | sort -r | head -1) + 3]
    awk -v total=$count '!/^#/ && NF>0 {seq++; n = total - length($1 $2 $3); printf "%d. \033[32m%s\033[0m \033[34m%s\033[0m \033[31m%s\033[0m ", seq, $1, $2, $3; for (i=1;i<=n;i++) printf "."; printf " "; print ($5 != "") ? substr($0, index($0, $5)) : "<none>"}' $repofile
  fi

  if [[ $count -eq 3 ]]; then
    echo -e "\033[31m<empty>\033[0m"
    exit
  fi
}

connect() {
  read -sp ">: " input

  local args=($(awk -v n=$input '!/^#/ && NF>0 {seq++; if (seq==n) {print $2"@"$1, $4; exit}}' $repofile))

  local dest=${args[0]}
  local jumpserver=${args[1]}

  if [[ -n $dest ]]; then
    echo -e "\033[31m$dest\033[0m"
  else
    echo -e "\033[31mexit\033[0m"
    exit
  fi

  if [[ "$jumpserver" == "direct" ]]; then
    if [[ -n "$identity_file" ]]; then
      ssh-copy-id -i $identity_file $dest
    fi

    ssh $dest
  else
    ssh -t $jumpserver "ssh $dest"
  fi
}

# ssh-copy-id
identity_file=

# show password for args
show_password=

while getopts ":h:i:pv" opt; do
  case $opt in
    i)
      if [[ ! -f "$OPTARG" ]]; then
        echo -e "\033[31minvalid identity_file. no such file or directory\033[0m"
        exit
      fi

      identity=$OPTARG
    ;;
    v)
      vim $repofile
      exit
    ;;
    p)
      show_password=true
    ;;
    ?) # 其他参数
      help
    ;;
  esac
done

# start
if [[ ! -f $repofile ]]; then
  cat > $repofile << EOF
# IP           User  Passwd  JumpServer        Remark
# 192.168.6.9  user  passwd  direct            direct connect server
# 192.168.9.6  user  passwd  user@192.168.6.9  bastion host connect

EOF
fi

display
connect
