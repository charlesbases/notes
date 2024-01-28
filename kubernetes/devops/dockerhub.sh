#!/usr/bin/env bash

root="yaml"
if [[ ! -d $root ]]; then
  echo "$root: No such file or directory"
  exit
fi

help() {
  echo """
Usage:
  ./$(basename $0) command

Commands:
  list       镜像列表
  pull       镜像拉取
  push       镜像推送"""
  exit
}

display() {
  ls $root/*.yaml | while read file; do
    if [[ -z $1 ]]; then
      echo -e "\033[32msearching for images in $file\033[0m"
    fi

    # search (custom)
    awk '!/#/ && /image: / {gsub(/ /, ""); sub(/image:/, ""); split($1, arr, "@"); print arr[1]}' $file | sort | uniq

    # search (images in tekton.yaml)
    awk '!/#/ && /.*-image/ {print}' $file | awk -v RS="," '!/.*-image/ {gsub(/"|]/, ""); split($1, arr, "@"); print arr[1]}' | uniq
  done
}

dockerpull() {
  display -q | while read image; do
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

  display -q | while read image; do
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
      display -q | while read image; do
        if [[ -z $(echo $image | grep $1) ]]; then
          sed -i "s@$image@$1/$image@g" $root/*.yaml
        fi
      done
    ;;
  esac
}

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
  *)
    help
  ;;
esac
