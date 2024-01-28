#!/usr/bin/env bash

# 私有镜像源
repository="10.64.21.107:83"
# 镜像匹配前缀
prefixs=("image: " "prometheus-config-reloader=")

# images.repo: 整理后的镜像列表
# images.link: 镜像所在的文件路径

help() {
  echo """
Usage:
  ./$(basename $0) [command]

Commands:
  push       镜像推送至私有仓库
  save       镜像保存至本地 './images' 目录
  tidy       yaml 文件整理
  apply      部署 Prometheus 相关 yaml
  delete     删除 Prometheus 相关 yaml
  replace    镜像源替换成 \"$repository\"
  download   镜像下载"""
  exit
}

kubesphere-cleaner() {
  if [[ $(kubectl get -n kubesphere-monitoring-system pods | grep prometheus-operator ) ]]; then
    # clean kubesphere-system
    installer=$(kubectl get pod -n kubesphere-system -l app=ks-installer -o jsonpath='{.items[0].metadata.name}')
    if [[ $installer ]]; then
      kubectl -n kubesphere-system exec $installer -- bash -c "ls /kubesphere/kubesphere/prometheus" | while read line; do
        kubectl -n kubesphere-system exec $installer -- bash -c "kubectl delete -f /kubesphere/kubesphere/prometheus/$line" 2>/dev/null
      done
    fi

    # clean kubesphere-monitoring-system
    kebuctl -n kubesphere-monitoring-system delete svc prometheus-operated 2>/dev/null
    kubectl -n kubesphere-monitoring-system delete pvc $(kubectl -n kubesphere-monitoring-system get pvc | awk '{if (NR > 1){print$1}}' | tr '\n' ' ') 2>/dev/null
  fi
}

# 统计镜像
carding() {
  ls $1 | while read file; do
    if [[ -d $file ]]; then
      carding $1/$file
    else
      if [[ ${file##*.} = "yaml" ]]; then
        for prefix in "${prefixs[@]}"; do
          cat $1/$file | grep "$prefix" | sed -s "s/.*$prefix//g" | sed -s 's/#.*//' | while read image; do
            echo "find \"$image\" in \"$1/$file\""

            echo $image >> images
            echo "$1/$file $image" >> images.link
          done
        done
      fi
    fi
  done
}

replace() {
  if [[ ! -f "images.link" ]]; then
    tidy_images
  fi

  cat images.link | while read line; do
    line=($line)
    for prefix in "${prefixs[@]}"; do
      if [[ $(cat ${line[0]} | grep "$prefix${line[1]}") ]]; then
        echo -e "replace \c"
        echo -e "\033[36m${line[1]}\033[0m\c"
        echo -e " to \c"
        echo -e "\033[36m$repository/${line[1]}\033[0m\c"
        echo " in \"${line[0]}\""

        sed -i -s "s@$prefix@$prefix$repository/@g" ${line[0]}
      fi
    done
  done
}

# yaml 整理
tidy_files() {
  dirs=(
    "alertmanager"
    "node-exporter"
    "blackbox-exporter"
    "kube-state-metrics"
    "prometheus-adapter"
    "grafana"
    "operator"
    "prometheus"
    "monitor"
  )

  for item in ${dirs[@]}; do
    if [[ ! -d $item ]]; then
      mkdir $item
    fi

    ls | grep ".yaml" | grep -i $item | while read file; do
      mv $file $item
    done
  done
}

tidy_images() {
  carding .
  echo

  # 镜像去重
  cat images.link | sort | uniq > images.link
  cat images | sort | uniq > images.repo && rm -f images
}

# 镜像推送
docker_push() {
  cat "images.repo" | while read image; do
    docker push $repository/$image
  done
}

# 镜像打包
docker_save() {
  if [[ ! -d images ]]; then
    mkdir images
  fi

  cat "images.repo" | while read image; do
    if [[ $repository ]]; then
      image=$repository/$image
    fi

    filename=${image##*/}
    filename=${filename//:/_}

    docker save -o ./images/$filename.tar $image
  done
}

# kubectl 部署
apply() {
  kubesphere-cleaner

  # setup(operator)
  if [[ -z $(kubectl get namespace | grep "monitoring ") ]]; then
    kubectl apply -f setup
  else
    echo -e "\033[33mingore setup.\033[0m"
  fi

  # prometheus
  ls | grep -v "setup" | while read dir; do
    if [[ -d $dir ]] && [[ $(ls $dir) ]]; then
      kubectl apply -f $dir
    fi
  done
}

# 删除本地镜像
delete() {
  # prometheus
  ls | grep -v "setup" | while read dir; do
    if [[ -d $dir ]]; then
      kubectl delete -f $dir
    fi
  done
}

# 镜像下载
download() {
  tidy_images

  # 镜像下载
  cat images.repo | while read image; do
    echo -e "\033[34mdocker pull $image\033[0m"
    docker pull $image
    if [[ $repository ]]; then
      docker tag $image $repository/$image
    fi
  done
  echo

  read -p "replace all to \"$repository\" ? (Y/N) " input
  if [[ $input =~ ^[yY]+$ ]]; then
    replace
  fi
}

case $1 in
  "" | help)
  help
  ;;
  push)
  docker_push
  ;;
  save)
  docker_save
  ;;
  tidy)
  tidy_files
  ;;
  apply)
  apply
  ;;
  delete)
  delete
  ;;
  replace)
  replace
  ;;
  download)
  download
  ;;
  *)
  echo """\
Error: unknown command in the script

Run './$(basename $0) help' for usage."""
  exit
  ;;
esac

echo -e "\033[32m\ncomplete! \033[0m"
