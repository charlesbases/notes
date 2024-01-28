#!/usr/bin/env bash

# 需要删除的目标镜像名称或 ID
target=$1

# 镜像版本, 不指定时, 删除 $target 匹配到的所有镜像
version=$2

repo="docker.clean"

# 镜像名称
image_name=
# 镜像版本
image_tag=
# 镜像 ID
image_id=
# 总数
total=

docker-clean() {
  local items=

  for (( i = 0; i < $total; i++ )); do
    local name=${image_name[i]}
    local tag=${image_tag[i]}
    local id=${image_id[i]}

    # 删除容器(镜像名匹配)
    items=$(docker ps -a | grep "$name:$tag" | awk '{print $1}')
    if [[ -n $items ]]; then
      docker rm -f $items >/dev/null 2>&1
    fi
    # 删除容器(镜像ID匹配)
    items=$(docker ps -a | grep "$id" | awk '{print $1}')
    if [[ -n $(docker ps -a | grep "$id") ]]; then
      docker rm -f $items >/dev/null 2>&1
    fi

    # 删除镜像
    if [[ -n $(docker images -a | grep "$name" | grep "$tag") ]]; then
      docker rmi -f $name:$tag >/dev/null 2>&1
    fi
  done

  # 删除 <none> 镜像
  items=$(docker images | grep "<none>" | awk '{print $3}')
  if [[ -n $items ]]; then
    docker rmi -f $items >/dev/null 2>&1
  fi
}

main() {
  docker images -a | grep "$target" | grep "$version" > $repo

  image_name=($(cat $repo | awk '{print $1}'))
  image_tag=($(cat $repo | awk '{print $2}'))
  image_id=($(cat $repo | awk '{print $3}'))
  total=${#image_name[@]}

  # 删除确认
  cat $repo
  read -sp "请确认 (Y/N): " input

  if [[ $input =~ ^[yY]+$ ]]; then
    echo -e "\033[32mY\033[0m"
  else
    echo -e "\033[31mEXIT\033[0m"
    exit
  fi

  docker-clean
  rm -rf $repo
}

if [[ -z $target ]]; then
  exit
fi

main
