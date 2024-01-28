# JuiceFS

[GitHub](https://github.com/juicedata/juicefs) [社区版文档](https://juicefs.com/docs/zh/community/introduction/) [CSI 文档](https://juicefs.com/docs/zh/csi/introduction)

------

## 1. apply

```shell
# Kubernetes Version >= v1.18
wget -O juicefs.yaml https://raw.githubusercontent.com/juicedata/juicefs-csi-driver/master/deploy/k8s.yaml

# Kubernetes Version < v1.18
wget -O juicefs.yaml https://raw.githubusercontent.com/juicedata/juicefs-csi-driver/master/deploy/k8s_before_v1_18.yam
```

```shell
# 查看 node 节点是否定制 kubelet 根目录
ps -ef | grep kubelet | grep root-dir

# 如果 `root-dir` 不为空并且不等于 '/var/lib/kubelet'
sed -i -s 's|/var/lib/kubelet|${root-dir}|g' juicefs.yaml
```

```shell
# 修改 juicefs 路径
sed -i -s 's|/var/lib/juicefs|/u01/etc/juicsfs|g' juicefs.yaml
```

```shell
# 镜像下载
cat juicefs.yaml | grep 'image:' | sed -s 's/.*image: //g' | sort | uniq
# juicedata/mount:v1.0.3-4.9.0

# 服务部署
kubectl apply -f juicefs.yaml

# 查看部署状态
kubectl -n kube-system get pods -l app.kubernetes.io/name=juicefs-csi-driver
```

---

## 2. StorageClass

```yaml
# 添加 secret 和 StorageClass
# https://juicefs.com/docs/zh/csi/guide/pv
---
apiVersion: v1
kind: Secret
metadata:
  name: juicefs
  namespace: kube-system
type: Opaque
stringData:
  name: "juicefs"
  metaurl: "redis://:password@192.168.1.1:6379/0"
  storage: "s3"
  bucket: "http://192.168.1.1:9000/juicefs" # MinIO
  access-key: "minioadmin"
  secret-key: "minioadmin"
  envs: "{TZ: Asia/Shanghai}"

---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: juicefs
  annotations:
    "storageclass.kubernetes.io/is-default-class": "true"
provisioner: csi.juicefs.com
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
parameters:
  csi.storage.k8s.io/node-publish-secret-name: juicefs
  csi.storage.k8s.io/node-publish-secret-namespace: kube-system
  csi.storage.k8s.io/provisioner-secret-name: juicefs
  csi.storage.k8s.io/provisioner-secret-namespace: kube-system
  juicefs/mount-image: juicedata/mount:v1.0.3-4.9.0
mountOptions:
- cache-dir=/u01/etc/juicsfs/
```

- 修改 Mount Pod 镜像

  ```shell
  # 查看当前 mount-image
  docker inspect $(docker images | grep 'juicefs-csi-driver' | awk 'NR==1{print $1":"$2}') | grep JUICEFS_MOUNT_IMAGE | awk '{gsub(/ /, ""); print}'
  ```

  ```shell
  # 第一种方案: 修改 StorageClass
  'kind: StorageClass' 添加 'params.juicefs/mount-image: juicedata/mount:v1.0.3-4.9.0'

  # 第二种方案: 添加 env (在不确认镜像版本时，推荐部署 juicefs 后修改 env)
  # daemonset
  kubectl -n kube-system set env daemonset/juicefs-csi-node -c juicefs-plugin JUICEFS_MOUNT_IMAGE=10.64.10.210:10083/juicedata/mount:v1.0.3-4.9.0
  # statefulset
  kubectl -n kube-system set env statefulset/juicefs-csi-controller -c juicefs-plugin JUICEFS_MOUNT_IMAGE=10.64.10.210:10083/juicedata/mount:v1.0.3-4.9.0
  ```
