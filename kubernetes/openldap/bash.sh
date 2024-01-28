#!/usr/bin/env bash

namespace=openldap

tidy() {
  cat openldap.yaml | grep 'image: ' | sed -s -e 's/.*image: //g' -e "s/'//g" | sort | uniq | while read item; do
    if [[ -z $(docker images | awk -v OFS=':' '{print $1,$2}' | grep $item) ]]; then
      docker pull $item
    fi

    if [[ $repository ]]; then
      docker tag $item $repository/$item
      docker push $repository/$item
    fi
  done

  # replace
  if [[ $repository ]]; then
    sed -i -s "s@image: @image: $repository/@g" openldap.yaml
  fi
}

apply() {
  tidy

  if [[ -z $(kubectl get namespace | grep $namespace) ]]; then
    kubectl create namespace $namespace
  fi
  
  if [[ $volume ]]; then
    # 修改挂载路径
    cat openldap.yaml | sed -s 's@/var/lib/ldap-account-manager/config@/var/lib/ldap-account-manager/source@' | kubectl apply -f -

    sleep 5

    # 等待容器启动
    while [[ -z $(kubectl get -n $namespace pod | grep openldap | grep Running) ]]; do
      sleep 1
    done

    # 备份原文件夹至修改后的挂载路径，同步至 pvc
    kubectl exec -n $namespace openldap-0 -c manager -- bash -c \
      "cd /var/lib/ldap-account-manager && cp -rf config/. source && chown -R www-data:root source"

    # 还原挂载目录
    kubectl get -n $namespace statefulsets openldap -o yaml | \
      sed -s 's@/var/lib/ldap-account-manager/source@/var/lib/ldap-account-manager/config@g' | \
      kubectl apply -f -
  else
    kubectl apply -f openldap.yaml
  fi
}

delete() {
  kubectl delete -f openldap.yaml
  
  if [[ $forced ]]; then
    # umount pvc
    kubectl get pvc -n $namespace | grep openldap | awk '{print$1}' | while read item; do
      kubectl delete pvc -n $namespace $item
    done

    # umount pv
    kubectl get pv | grep openldap/ | awk '{print$1}' | while read item; do
      kubectl delete pv $item
    done
  fi
}

volume=""
forced=""
repository=""

case $2 in
  "")
  ;;
  -r)
  repository="$3"
  ;;
  -v)
  volume="true"
  ;;
  -f)
  forced="true"
  ;;
  *)
  echo "invalid option"
  exit
esac

case $1 in
  tidy)
  tidy
  ;;
  apply)
  apply
  ;;
  delete)
  delete
  ;;
  *)
  echo """
Usage:
  ./$(basename $0) command [options]

Commands:
  tidy       镜像拉取
  apply      部署 openldap
  delete     卸载 openldap

Options:
  -r         私有仓库地址
  -v         修复 lam 挂载问题
  -f         强制卸载 openldap, 并清理挂载卷"""
exit
  ;;
esac
