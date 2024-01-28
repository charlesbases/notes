#!/usr/bin/env bash

help() {
  echo """\
Usage:
  ./$(basename $0) [options] <command>

Options:
  -f         从指定路径中整理镜像列表
  -o         镜像输出路径

Commands:
  list       镜像列表
  pull       镜像拉取
  push       镜像推送
  clean      本地镜像清理"""
  exit
}

display() {
  # $filepath 不是文件夹，并且不是 yaml 文件
  if [[ -f $filepath ]] && [[ -z $(echo $filepath | grep '.yaml$') ]] ; then
    grep -v '^#' $filepath
    return
  fi

  # $filepath 是文件夹，或者是 yaml 文件
  if [[ -d $filepath ]] || [[ $(echo $filepath | grep '.yaml$') ]]; then
    rm -rf dockerhub.tmp
    find $filepath -type f | grep '.yaml$' | while read file; do
      awk '!/#/ && /image:/ {gsub(/ |'\''|"/, ""); print}' $file | awk -v FS="image:" '{if ($2) {print $2}}' | awk -F@ '{print $1}' >> dockerhub.tmp
    done
    cat dockerhub.tmp | sort | uniq
    rm -rf dockerhub.tmp
    return
  fi

  echo -e "\033[31mopen $filepath: No such file or directory\033[0m"
  exit
}

dockerpull() {
  display | while read image; do
    # docker pull
    echo -e "\033[32mdocker pull $image\033[0m"
    if [[ -z $(docker images | awk '{print $1":"$2}' | grep $image) ]]; then
      docker pull $image
    else
      echo "Digest: $(docker inspect --format='{{.Id}}' $image)"
    fi

    echo
  done
}

dockerpush() {
  if [[ -z "$1" ]]; then
    echo "Error: invalid repository."
    echo "usage: $0 push <repository>"
    exit
  fi

  display | while read image; do
    # docker pull
    echo -e "\033[32mdocker pull $image\033[0m"
    if [[ -z $(docker images | awk '{print $1":"$2}' | grep $image) ]]; then
      docker pull $image
    else
      echo "Digest: $(docker inspect --format='{{.Id}}' $image)"
    fi

    # docker push
    echo -e "\033[36mdocker push $image\033[0m"
    docker tag $image $1/$image
    docker push $1/$image

    echo
  done

  read -p "replace repository? (Y/N): " oper

  case $oper in
    Y|y)
      display | while read image; do
        if [[ -z $(echo $image | grep $1) ]]; then
          sed -i "s|$image|$1/$image|" $filepath
        fi
      done
    ;;
  esac
}

dockersave() {
  if [[ ! -d $(dirname $output) ]]; then
    mkdir -p $(dirname $output)
  fi

  display | while read image; do
    # docker pull
    echo -e "\033[32mdocker pull $image\033[0m"
    docker pull $image
    echo
  done

  # docker save
  echo -e "\033[34mdocker save -o $output\033[0m"
  docker save -o $output $(display | awk -v ORS=" " '{print}')
}

dockerclean() {
  display | while read image; do
    echo -e "\033[34mdocker rmi -f $image\033[0m"

    docker rmi -f $image 2>&1
    echo
  done
}

output="output/$(date +"%Y%m%d%H%M%S").tar"
filepath="."

while getopts ":f:o:h" opt; do
  case $opt in
    o)
    output=$OPTARG
    ;;
    f)
    filepath=$OPTARG
    ;;
    h)
    help
    ;;
    ?)
    echo "Error: invalid flag: '-$OPTARG'"
    echo "See '$0 -h' for usage."
    exit
    ;;
  esac
done

shift $(($OPTIND - 1))

case $1 in
  ""|list)
  display
  ;;
  pull)
  dockerpull
  ;;
  push)
  dockerpush $2
  ;;
  save)
  dockersave
  ;;
  clean)
  dockerclean
  ;;
  *)
  help
  ;;
esac
