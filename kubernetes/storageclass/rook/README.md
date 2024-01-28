# Rook

[github](https://github.com/rook/rook) [官方文档](https://docs.ceph.com/en/latest) [架构文档](https://zhuanlan.zhuhu.com/p/468843946)

---

ver: v1.11

---

```shell
# 查看版本兼容性
https://rook.io/docs/rook/latest-release/Getting-Started/quickstart/
```

---

## 1. install

```shell
ver=v1.11

git clone -b $ver --single-branch https://github.com/rook/rook.git

cd rook/deploy/examples

# crds.yaml     -- CustomResourceDefinition
# common.yaml   -- rbac
# operator.yaml -- operator
# cluster.yaml  -- ceph cluster
# toolbox.yaml  -- toolbox
```

- ##### images

  ```shell
  # 镜像列表
  # awk '/image: / {sub(/image:/, ""); gsub(/ /, ""); print} /IMAGE:/ {print}' cluster.yaml operator.yaml | sed 's/.*"\(.*\)".*/\1/'

  # 镜像下载
  awk '/image: / {sub(/image:/, ""); gsub(/ /, ""); print} /IMAGE:/ {print}' cluster.yaml operator.yaml | sed 's/.*"\(.*\)".*/\1/' | while read image; do docker pull $image; done

  # 镜像推送至私有仓库
  registry=10.64.10.210:10083
  awk '/image: / {sub(/image:/, ""); gsub(/ /, ""); print} /IMAGE:/ {print}' cluster.yaml operator.yaml | sed 's/.*"\(.*\)".*/\1/' | while read image; do docker tag $image $registry/$image; docker push $registry/$image; sed -i -e "s|image: $image|image: $registry/$image|" -e "s|\"$image\"|\"$registry/$image\"|" -e 's/# ROOK_CSI_\(.*\)_IMAGE/ROOK_CSI_\1_IMAGE/' cluster.yaml operator.yaml; done
  ```

- ##### operator

  ```shell
  # 修改 "kubelet root-dir" . (若修改)
  awk '/ROOK_CSI_KUBELET_DIR_PATH/ {print FILENAME":"FNR}' operator.yaml

  # 若网络插件为 calico，则需要修改 hostNetwork: true
  sed -i 's/#hostNetwork: true/hostNetwork: true/' operator.yaml
  ```

- ##### cluster

  ```shell
  # 修改 ceph 挂载目录
  # 注意: 只能挂载分区根目录
  sed -i 's|dataDirHostPath: .*|dataDirHostPath: /u01|' cluster.yaml

  # dashboard 使用 http
  sed -i 's/ssl: true/ssl: false/' cluster.yaml
  ```

- ##### cephblockpool

  ```yaml
  apiVersion: ceph.rook.io/v1
  kind: CephBlockPool
  metadata:
    name: replicapool
    namespace: rook-ceph # namespace:cluster
  spec:
    # The failure domain will spread the replicas of the data across different failure zones
    failureDomain: host
    # For a pool based on raw copies, specify the number of copies. A size of 1 indicates no redundancy.
    replicated:
      size: 3
  ```

- ##### storageclass

  ```yaml
  apiVersion: storage.k8s.io/v1
  kind: StorageClass
  metadata:
     name: rook-ceph
  provisioner: rook-ceph.ceph.rook.io/bucket # driver:namespace:cluster
  # set the reclaim policy to retain the bucket when its OBC is deleted
  reclaimPolicy: Retain
  parameters:
     objectStoreName: my-store # port 80 assumed
     objectStoreNamespace: rook-ceph # namespace:cluster
     # To accommodate brownfield cases reference the existing bucket name here instead
     # of in the ObjectBucketClaim (OBC). In this case the provisioner will grant
     # access to the bucket by creating a new user, attaching it to the bucket, and
     # providing the credentials via a Secret in the namespace of the requesting OBC.
     #bucketName:
  ```

```shell
# apiresources & rbac & operator
kubectl apply -f crds.yaml -f common.yaml -f operator.yaml

# 查看 operator 是否正常运行
kubectl -n rook-ceph get pod | grep -- rook-ceph-operator

# ceph cluster
kubectl apply -f cluster.yaml

# 查看 osd 节点是否正常运行
kubectl -n rook-ceph get pod | grep -- rook-ceph-osd

# ceph pool
kubectl apply -f pool.yaml
```

---

## 2. dashboard

```shell
# 添加 ingress

# 查看密码. username: admin
kubectl -n rook-ceph get secrets rook-ceph-dashboard-password -o jsonpath='{.data.password}' | base64 --decode && echo
```

---

## 9. common issues

```shell
# kubectl apply -f toolbox.yaml
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- bash
```

- ##### no osd running

  ```shell
  # osd 挂载只能选择设备根目录，而不支持子路径挂载
  kubectl -n rook-ceph logs $(kubectl -n rook-ceph get pod | grep -- rook-ceph-osd-prepare | awk 'NR==1{print $1}')
  ```
