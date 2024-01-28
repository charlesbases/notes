#!/usr/bin/env bash

set -e

# 服务列表
services=(
"rpcbind.service"
"kubelet.service"
)

homedir=$HOME/.watchers

# 日志文件
logfile=$homedir/.restart.log

mkdir -p $homedir

cleanup() {
  if [[ ! -f "$logfile" ]]; then
    return
  fi

  local lastmonth=$(date -d "1 month ago" "+%Y-%m")
  if [[ -f "$logfile.$lastmonth" ]]; then
    return
  fi

  local month=$(date "+%Y-%m")
  if [[ -n $(cat $logfile | grep "$month") ]]; then
    return
  fi

  if [[ -n $(ls -a $homedir | grep ".restart.log.") ]]; then
    rm -rf $homedir/.restart.log.*
  fi

  mv $logfile $logfile.$lastmonth
}

# log cleanup
cleanup

# service health check
for srv in "${services[@]}"; do
  if [[ -z $(systemctl status $srv | grep -o 'active (running)') ]]; then
    curr=$(date "+%Y-%m-%d %H:%M:%S") && echo "$curr ==> systemctl restart $srv"  >> $logfile
    systemctl restart $srv

    if [[ -z $(systemctl status $srv | grep -o 'active (running)') ]]; then
      curr=$(date "+%Y-%m-%d %H:%M:%S") && echo "$curr ==> systemctl restart $srv failed" >> $logfile
    fi
  fi
done
