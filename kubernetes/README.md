# Kubernetes

[v1.23](https://gitee.com/moxi159753/LearningNotes/tree/master/K8S)

---

## 1. 安装

### 1.1. 环境准备

- ##### firewalld

  ```shell
  # 关闭防火墙
  if command -v firewalld &> dev/null; then sudo sh -c "systemctl stop firewalld && systemctl disable firewalld" && sudo apt remove firewalld --purge -y; fi
  ```

- ##### swap

  ```shell
  # 临时
  swapoff -a
  # 永久
  sed -ri 's/.*swap.*/#&/' /etc/fstab
  ```

- ##### hostname

  ```shell
  # 修改 hostname
  hostnamectl set-hostname xxxx

  # 添加 hosts
  cat >> /etc/hosts << EOF
  192.168.1.10 kube-master
  192.168.1.11 kube-node-1
  192.168.1.12 kube-node-2
  192.168.1.13 kube-node-3
  EOF
  ```

- ##### selinux

  ```shell
  # 临时关闭
  setenforce 0

  # 永久关闭
  sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
  ```

- ##### ipvs

  ```shell
  # 开启内核模块(ipvs)
  cat > /etc/modules-load.d/k8s.conf << EOF
  overlay
  br_netfilter
  ip_vs
  ip_vs_sh
  ip_vs_rr
  ip_vs_wrr
  nf_conntrack
  EOF

  # 调整内核参数
  cat > /etc/sysctl.d/k8s.conf << EOF
  net.ipv4.ip_forward = 1
  net.bridge.bridge-nf-call-iptables = 1
  net.bridge.bridge-nf-call-ip6tables = 1
  vm.swappiness = 0
  vm.panic_on_oom = 0
  fs.inotify.max_user_instances = 8192
  fs.inotify.max_user_watches = 1048576
  fs.file-max = 52706963
  fs.nr_open = 52706963
  net.ipv6.conf.all.disable_ipv6 = 1
  net.netfilter.nf_conntrack_max = 2310720
  EOF

  sysctl --system
  ```

- ##### ntpdate

  ```shell
  # debain 使用 ntpd
  # sudo apt install -y ntp

  # centos 使用 ntpdate
  # sudo yum install -y ntp
  ```

  ```shell
  # master
  ```

  ```shell
  # node
  ```

  ```shell
  # 时间同步
  ## netdate 系统时间
  sudo sh -c "apt install ntp -y && ntpd time.windows.com && timedatectl set-timezone 'Asia/Shanghai'"
  # sudo sh -c "yum install ntpdate -y && ntpdate time.windows.com && timedatectl set-timezone 'Asia/Shanghai'"

  ## hwclock 硬件时间
  sudo hwclock -w
  ```

---

### 1.2. 组件安装

- ##### debian 11

  ```shell
  # 下载 apt 依赖包
  sudo apt update && sudo apt install -y apt-transport-https ca-certificates curl

  # 下载 Kubernetes 签名密钥
  curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add -

  # 添加 apt Kubernetes 源
  cat > /etc/apt/sources.list.d/kubernetes.list << EOF
  deb http://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
  EOF
  # sudo sh -c "echo 'deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main' > /etc/apt/sources.list.d/kubernetes.list"

  # 安装 Kubernetes
  sudo apt update && sudo apt reinstall kubeadm=1.24.00-00 kubelet=1.24.00-00 kubectl=1.24.00-00 -y

  # 修改 kubelet.service
  # [1.4.1]

  # 开机启动
  sudo sh -c "systemctl enable kubelet.service && systemctl start kubelet.service"

  # oh-my-zsh plugins
  ...
  autoload -Uz compinit
  compinit

  plugins=(git kubectl)
  source <(kubectl completion zsh)
  ...

  ```

- ##### centos

  ```shell

  ```

- ##### rpm

  ```shell
  # http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/Packages/

  # kubeadm-1.23.16-0.x86_64.rpm
  # kubelet-1.23.16-0.x86_64.rpm
  # kubectl-1.23.16-0.x86_64.rpm
  # cri-tools-1.26.0-0.x86_64.rpm
  # kubernetes-cni-1.2.0-0.x86_64.rpm

  # 安装 rpm 包
  rpm -ivh *.rpm --nodeps --force

  # 安装依赖
  sudo apt install -y socat conntrack

  # 开机启动
  sudo sh -c "systemctl enable kubelet.service && systemctl start kubelet.service"
  ```

---

### 1.3. 镜像列表

#### 1.3.1. kubernetes

```shell
# 基础镜像离线下载
# sudo kubeadm config images list

repository="10.64.10.210:10083"
cat kubernetes_v1.21.11.repo | while read line; do docker pull $line && docker tag $line $repository/$line && docker push $repository/$line; done
```

#### 1.3.2. [calico](#1.6.-网络插件)

```shell
```

#### 1.3.3. [ingress-nginx](./ingress/README.md)

```shell
```

#### 1.3.4. [kubesphere](./kubesphere/README.md)

```shell
```

#### 1.3.5. [metrics](#5.3.-metrics)

```shell

```

---

### 1.4. 服务启动

- #### master

  ```shell
  ip=192.168.1.10
  version=1.23.9

  # kubeadm init (k8s.gcr.io)
  # sudo kubeadm init --apiserver-advertise-address $ip --kubernetes-version $version --service-cidr=10.96.0.0/12  --pod-network-cidr=192.168.0.0/16 --pod-network-cidr=192.168.0.0/16

  # kubeadm init (repository)
  # 注意：使用指定镜像源时，将替换默认镜像源前缀 (k8s.gcr.io)，镜像推送时需修改镜像路径
  # repository=repository.aliyuncs.com/google_containers
  repository="10.64.10.210:10083/k8s.gcr.io"
  sudo kubeadm init --apiserver-advertise-address $ip --image-repository $repository --kubernetes-version $version --service-cidr=10.96.0.0/12  --pod-network-cidr=192.168.0.0/16

  # 创建 master 账户
  rm -rf $HOME/.kube && mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

  # 安装网络插件
  kubectl apply -f cni-calico.yaml

  # 修改 "--bind-address"
  ## kube-scheduler
  sudo sh -c "sed -s -i 's/--bind-address=127.0.0.1/--bind-address=0.0.0.0/g' /etc/kubernetes/manifests/kube-scheduler.yaml"
  ## kube-controller-manager
  sudo sh -c "sed -s -i 's/--bind-address=127.0.0.1/--bind-address=0.0.0.0/g' /etc/kubernetes/manifests/kube-controller-manager.yaml"

  # token
  kubeadm token create --print-join-command
  # token(不过期)
  kubeadm token create --print-join-command --ttl 0

  # [node] kubeadm join ...

  # 验证
  kubectl get nodes

  # metrics (5.3. metrics)
  ```

- #### node

  ```shell
  # 重新加入
  # sudo sh -c "systemctl stop kubelet.service && rm -rf /etc/kubernetes/{kubelet.conf,pki/ca.crt}"

  # join
  # sudo kubeadm join ...
  ```

---

### 1.5. 配置优化

#### 1.5.1. root-dir

- ##### docker

  ```shell
  # 查看当前 docker 数据存储目录
  sudo docker info | grep 'Docker Root Dir'

  # 修改数据存储目录
  sudo vim /etc/docker/daemon.json
  ...
  {
    "data-root": "/u01/etc/docker",
  }
  ...

  # 重启 docker
  sudo systemctl restart docker
  ```

- ##### kubelet

  - 方案一：创建软链（推荐）

    ```shell
    # stop
    sudo systemctl stop kubelet

    # 数据迁移
    sudo mv /var/lib/kubelet /u01/etc/kubelet

    # 创建软链
    sudo ln -s /u01/etc/kubelet /var/lib/

    # 重启 kubelet
    sudo systemctl restart kubelet
    ```

  - 方案二：修改 root-dir

    ```shell
    # stop
    sudo systemctl stop kubelet

    # 数据迁移
    sudo mv /var/lib/kubelet/{pods,pod-resources} /u01/etc/kubelet/

    # 查看当前 root-dir. (default: "/var/lib/kubelet")
    sudo systemctl cat kubelet | grep -- --root-dir

    # 查看 kubelet.service 配置
    sudo systemctl cat kubelet

    # 1、可直接修改 "kubelet.service"
    ...
    [Service]
    ExecStart=/usr/bin/kubelet [args]
    ...

    # 2、或者修改 "kubeadm.conf"
    ...
    [Service]
    Environment="KUBELET_EXTRA_ARGS=--root-dir=/u01/etc/kubelet"
    ...

    # KUBELET_EXTRA_ARGS
    # --root-dir=/u01/etc/kubelet            => kubelet 数据存储目录
    # --eviction-hard=nodefs.available<1%    => 在 kubelet 相关存储不足 1% 时，开始驱逐 Pod
    # --eviction-hard=nodefs.available<10Gi  => 在 kubelet 相关存储不足 10G 时，开始驱逐 Pod
    # --eviction-hard=imagefs.available<1%   => 在容器运行时，相关存储不足 1% 时，开始驱逐 Pod

    # 重启 kubelet
    sudo systemctl restart kubelet
    ```

#### 1.5.2. kube-proxy

```shell
# 使用 ipvs 模式
## mode: "" => mode: "ipvs"
kubectl edit -n kube-system configmaps kube-proxy

# 重启 kube-proxy
kubectl delete -n kube-system pods $(kubectl get pods -n kube-system | grep kube-proxy | awk '{print $1}')
```

---

### 1.6. 网络插件

- ##### calico

  ```shell
  # version=v3.23 && wget -O calico.yaml https://docs.projectcalico.org/$version/manifests/calico.yaml
  # kubectl apply -f calico.yaml

  # 镜像列表
  sed -n '/image:/ s/        image://p' calico.yaml | sort | uniq

  # 镜像下载，并推送到私有仓库

  # 修改 calico 网卡发现机制
  sed -s -i 's/- name: CLUSTER_TYPE/- name: IP_AUTODETECTION_METHOD\n              value: "interface=ens.*"\n            - name: CLUSTER_TYPE"/g' calico.yaml

  # 部署 CNI 网络插件
  kubectl apply -f cni-calico.yaml

  # 查看状态
  kubectl get pods -n kube-system

  # 卸载
  kubectl delete -f cni-calico.yaml
  ## master/node
  sudo sh -c 'modprobe -r ipip && rm -rf /var/lib/cni /etc/cni/net.d/* && systemctl restart kubelet.service'
  ```

- ##### flannel

  ```shell
  # kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

  # 手动拉取镜像
  docker pull flannelcni/flannel:v0.18.1
  docker pull flannelcni/flannel-cni-plugin:v1.1.0

  # 部署 CNI 网络插件
  kubectl apply -f kube-flannel.yaml

  # 查看状态
  kubectl get pods -n kube-system
  ```

---

## 2. 组件说明

- ##### ApiServer

  ```yaml
  # 所有服务统一入口
  ```

- ##### Scheduler

  ```yaml
  # 任务调度/分配
  ```

- ##### ControllerManager

  ```yaml
  # 维持期望副本数目
  ```

- ##### ETCD(v3)

  ```yaml
  # 键值对数据库，集群数据存储
  ```

- ##### Kubelet

  ```yaml
  # 控制容器引擎(docker、container)，实现容器的生命周期管理
  ```

- ##### Kube-Proxy

  ```yaml
  # 写入规则至 IPVS、IPTABLES，实现服务映射访问
  ```

---

## 3. 插件说明

- ##### CoreDNS

  ```yaml
  # 可以为集群中的 service 创建一个 <域名:IP> 的对应关系体系
  ```

- ##### [KubeSphere](./kubesphere/README.md)

  ```shell
  # Kubernetes 管理平台
  ```

- ##### [IngressController](./storageclass/README.md)

  ```yaml
  # 官方实现四层网络代理，IngressController 可以实现七层网络代理(实现域名访问)
  ```

- ##### [Prometheus](./prometheus/README.md)

  ```yaml
  # Kubernetes 集群监控平台
  ```

- ##### EFK

  ```yaml
  # Kubernetes 集群日志分析平台
  ```

---

## 4. 资源清单

### 4.1. [ConfigMap](./configmap.yaml)

```shell
# 存储不加密数据。多用于配置文件
# kubectl create configmap nginx --from-file nginx.conf -o yaml --dry-run=client > nginx.configmap.yaml
```

---

### 4.2. [DaemonSet](./daemonset.yaml)

```shell
# 守护进程。每个 node 运行一个此 Pod
```

---

### 4.3. [Deployment](./deploy.yaml)

```shell
# 无状态应用
```

---

### 4.4. [HorizontalPodAutoscaler](./horizontal.yaml)

```shell
# Pod 横向自动扩容。根据 Pod 资源利用率，自动伸缩 Pod
```

---

### 4.5. [Ingress](./ingress/README.md)

---

### 4.6. [Job&CronJob](./job.yaml)

---

### 4.7. [PersistentVolume](./persistentvolume.yaml)

---

### 4.8. [rbac](./rbac.yaml)

```txt
rbac:
  是 Kubernetes 集群基于角色的访问控制，实现授权决策，允许通过 Kubernetes API 动态配置策略。

Role:
  是一组权限的集合，例如可以包含列出 Pod、Deployment 等资源类型的权限。Role 用于给某个 Namespace 中的资源进行鉴权

ClusterRole:
  是一组权限的集合，但与Role不同的是，ClusterRole可以在包括所有NameSpce和集群级别的资源或非资源类型进行鉴权。
```

- ##### apiGroups

  ```shell
  # ""
  # "apps"
  # "batch"
  # "autoscaling"
  ```

- ##### resources

  ```shell
  # "services"
  # "endpoints"
  # "pods"
  # "secrets"
  # "configmaps"
  # "crontabs"
  # "deployments"
  # "jobs"
  # "nodes"
  # "rolebindings"
  # "clusterroles"
  # "daemonsets"
  # "replicasets"
  # "statefulsets"
  # "horizontalpodautoscalers"
  # "replicationcontrollers"
  # "cronjobs"
  ```

- ##### verbs

  ```shell
  # "get"
  # "list"
  # "watch"
  # "create"
  # "update"
  # "patch"
  # "delete"
  # "exec"
  ```

---

### 4.9. [Secret](./secret.yaml)

- ##### [Opaque](./secret.yaml)

  ```shell
  # 查看 opaque 明文编码
  kubectl get secret mysecret -o jsonpath='{.data.username}' | base64 --decode
  ```

- ##### kubernetes.io/tls

  ```shell
  kubectl create secret tls $name --cert $crtfile --key $keyfile
  ```

- ##### kubernetes.io/dockerconfigjson

  ```shell
  kubectl create secret docker-registry $name --docker-server="ip:port" --docker-username="username" --docker-password="password"
  ```

---

### 4.10. [Service](./service.yaml)

```shell
# 防止 Pod 失去连接、负载均衡
```

---

### 4.11. [StatefulSet](./statefulset.yaml)

```shell
# 有状态应用
# 需指定 '.spec.serviceName'
```

---

### 4.12. StorageClass

- ##### local

  ```yaml
  ---
  kind: StorageClass
  apiVersion: storage.k8s.io/v1
  metadata:
    name: local
    annotations:
    	"storageclass.kubernetes.io/is-default-class": "true"
  reclaimPolicy: Retain
  provisioner: kubernetes.io/no-provisioner
  volumeBindingMode: WaitForFirstConsumer
  ```

- ##### nfs

  ```shell
  # 搭建 nfs 服务器
  ```

  ```shell
  # https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner

  # 添加仓库源
  helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/

  # 安装
  helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
      --set nfs.server=192.168.1.10 \
      --set nfs.path=/data/nfs
  ```

  ```shell
  kind: StorageClass
  apiVersion: storage.k8s.io/v1
  metadata:
    name: storage-nfs
    namespace: app
    annotations:
    	"storageclass.kubernetes.io/is-default-class": "true"
  reclaimPolicy: Retain
  provisioner: example.com/external-nfs
  parameters:
    server: 192.168.1.10
    path: /data/nfs
  ```

- ##### [rook](./storageclass/rook/README.md)

- ##### [juicefs](./storageclass/juicefs/README.md)

---

## 5. 扩展信息

```shell
# helm:     命令行工具
# chart:    yaml 集合
# release:  基于 chart 的部署实体，应用级别的版本控制
```

- ##### install

  ```shell
  ver=v3.9.0 && wget -c https://get.helm.sh/helm-$ver-linux-amd64.tar.gz -O - | sudo tar -xz -C $HOME
  mv $HOME/linux-amd64/helm /usr/local/bin/

  # 添加仓库源
  # helm repo add [名称] [地址]
  # 官方。国内不好用
  helm repo add official https://brigadecore.github.io/charts
  # 阿里
  helm repo add aliyun https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts

  # 更新仓库源
  helm repo update

  # 删除仓库源
  helm repo remove [名称]
  ```

- ##### apply

  ```shell
  # 创建 Chart
  helm create [mychart]
  ## Chart.yaml: chart 属性
  ## templates: yaml 文件集合
  ## values.yaml: 全局属性。可在 templates 中引用

  # 安装
  helm install [别名] [mychart]

  # 更新
  helm upgrade [别名] [mychart]
  ```

- ##### param

  ```shell
  # values.yaml
  ···
  key: value
  ···

  # templates
  ···
  ## 变量
  {{ .Values.key}}
  ## 版本
  {{ .Release.Name}}
  ···
  ```

---

### 5.2. [probe](./probe.yaml)

```shell
# Probe 探针

1. 启动探针(startupProbe)：如果在 (failureThreshold*periodSeconds) 时间内未成功启动， 将杀死容器，根据 Pod 的 restartPolicy 来操作

2. 存活探针(livenessProbe)：存活检查。判断 Pod 是否健康。如果探测失败，则根据 restartPolicy 策略来重启容器。
表现形式为：执行 `kubectl get pod` 命令，'STATUS' 列

3. 就绪探针(readinessProbe)：就绪检查。可以理解为这个 Pod 可以接受请求和访问，如果检查失败，会把 Pod 从 service endpoints 中剔除（不接受 service 流量）。探测失败不会重启。
表现形式为：执行 `kubectl get pod` 命令，'READY' 列

注意：
  livenessProbe、readinessProbe 在容器整个生命周期中保持运行状态；
  livenessProbe 不等待 readinessProbe 成功，若需要在存活探针之前等待，应使用 startupProbe 或 initialDelaySeconds
```

```shell
# 检查方式

1. exec: 执行 exec 命令，返回状态码是 0 为成功
2. httpGet: 发送 HTTP 请求，返回 200-400 范围状态码为成功
3. tcpSocket: 发起 TCP Socket 建立成功

# periodSeconds: 执行探测的时间间隔。(default: 10)
# timeoutSeconds: 超时时间。(default: 1)
# successThreshold: 最小连续探测成功数。(default: 1)
# failureThreshold: 连续探测失败数。连续失败后，触发重启策略
# initialDelaySeconds: Pod 启动后，延迟多少秒开始探测
```



---

### 5.3. metrics

```shell
# https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.6.3/components.yaml

# enable-aggregator-routing
if [[ $(ps -ef | grep apiserver | grep enable-aggregator-routing) ]]; then echo sudo sh -c "sed -i -s '/--enable-bootstrap-token-auth/a\    - --enable-aggregator-routing=true' apiserver.yaml"; fi

# 修改 metrics.yaml
sed -i -s 's/InternalIP,ExternalIP,Hostname/InternalIP/' metrics.yaml
sed -i -s '/--metric-resolution/a\        - --kubelet-insecure-tls' metrics.yaml
```

---

## 6. 常用命令

### 6.1. namespace

```shell
# 创建 namespace
kubectl create namespace app
# 配置首选 namespace
kubectl config set-context --current --namespace=app

# 查看当前上下文 namespace
kubectl config view --minify --output 'jsonpath={..namespace}'
```

### 6.2. pod

```shell
# 镜像升级
kubectl set image deployment app nginx=nginx:latest

# 进入容器
kubectl exec -it app -c srv -- bash

# 执行命令
kubectl exec app -c srv -- "date"
```

### 6.3. label

```shell
# 查看节点标签
kubectl get nodes --show-labels
# 添加节点标签
kubectl label nodes <node-name> <label-key>=<label-value>
# 删除标签
kubectl label nodes <node-name> <label-key>-
```

### 6.4. taint

```shell
# 查看 master 节点
kubectl describe nodes kube-master
# 去除污点
kubectl taint nodes kube-master node-role.kubernetes.io/master:NoSchedule-
```

### 6.5. apply

```shell
# 从管道创建资源
cat nginx.yaml | kubectl apply -f -
```

---

## 7. 退出状态

### 7.1. OOMKilled

```shell
# Exit 137
# 内存不足
```

---

## 8. 问题排查

### ————————————

### [ERROR CRI]

```shell
# 容器运行平台报错

# 查看 kubelet 日志
sudo journalctl -xeu kubelet

# 查看运行平台日志(docker/containerd)
sudo journalctl -xeu containerd

# 重启容器运行平台
rm -rf /etc/containerd/config.toml && systemctl restart containerd
```

---

### [ERROR Swap]

```shell
# 未关闭虚拟内存
# 临时关闭
swapoff -a
# 永久关闭
sed -ri 's/.*swap.*/#&/' /etc/fstab
```

---

### [ERROR NumCPU]

```shell
# 错误的 CPU 核心数。最少为 2.
```

---

### [ERROR Port-10250]

```shell
# kubelet 端口被占用

# 查看 kubelet 日志
sudo journalctl -xeu kubelet

# 查看端口占用
sudo lsof -i :10250

# 杀掉端口占用程序
kill -9 [pid]

# 重启 kubelet 或 kubernetes
# sudo systemctl restart kubelet
kubeadm reset -f && rm -rf $HOME/.kube
```

---

### timed out

```shell
# k8s 基础镜像拉取失败

# 下载基础镜像
docker pull k8s.gcr.io/...

# 重启 docker
systemctl restart docker

# 重启 kubelet
systemctl stop kubelet
```

---

### BIRD is not ready

```shell
# 调整 calico 网络插件的网卡发现机制

# 查看网卡
ip link show

# 添加环境变量 'IP_AUTODETECTION_METHOD'
kubectl edit daemonsets -n kube-system calico-node

...
          env:
            - name: IP_AUTODETECTION_METHOD
              value: "interface=ens.*"
            - name: CLUSTER_TYPE"
              value: "k8s,bgp"
...
```

---

### connection refused

```shell
# 未找到 kubeconfig 文件

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

---

### kubelet is not running

```shell
# 查看 kubelet 状态
sudo systemctl status kubelet

# 查看 kubelet 日志
sudo journalctl -xeu kubelet

# 重启 kubelet
sudo systemctl restart kubelet
```

---

### coredns ContainerCreating

```shell
# 查看 cni 版本是否与 kubernetes 版本兼容

# coredns 未就绪与 cni 插件有必然联系
kubectl describe pods -n kube-system  calico-

# 删除节点上 cni 安装信息
sudo rm -rf /etc/cni/net.d/* /var/lib/cni/calico

# 重启 kubelet
sudo systemctl restart kubelet
```

---

### ————————————

---

### pod-Evicted

```shell
# 查看
kubectl get pods -A | grep Evicted

# 清理
kubectl get pods -A | grep Evicted | awk '{print $1}' | sort | uniq | while read line; do kubectl delete -n $line pods $(kubectl get pods -n $line | grep Evicted | awk '{print $1}'); done
```

---

### orphaned pod

```shell
# Pod 异常退出，导致数据卷挂载点在卸载过程中没有清理干净，最终导致Pod沦为僵尸Pod。Kubelet的GC流程对数据卷垃圾回收实现并不完善，目前需要手动或脚本自动化实现垃圾挂载点的清理工作。
```

- ##### 脚本清理

  ```shell
  curl https://raw.githubusercontent.com/AliyunContainerService/kubernetes-issues-solution/master/kubelet/kubelet.sh | bash
  ```

- ##### 手动清理

  ```shell
  # 查看 orphaned pod
  # <node>
  sudo journalctl -xeu kubelet | grep -- orphaned | sed 's/.*\\"\(.*\)\\".*/\1/' | sort | uniq
  # sudo journalctl -xeu kubelet | grep -- orphaned | sed 's/.*\\"\(.*\)\\".*/\1/' | sort | uniq | awk -v ORS=' ' '{print}' && echo

  # 查看 pod name
  # <master>
  podids=$(kubectl get pod -A -o jsonpath='{range .items[*]}{.metadata.namespace} {.metadata.name} {.spec.nodeName} {.metadata.uid} {"\n"}'); sudo journalctl -xeu kubelet | grep -- orphaned | sed 's/.*\\"\(.*\)\\".*/\1/' | sort | uniq | while read line; do echo $podids | grep $line; done

  # 清理相关 pod 目录
  # <node>
  ```

  - ###### node

    ```shell
    # 获取 podid
    sudo journalctl -xeu kubelet | grep -- orphaned | sed 's/.*\\"\(.*\)\\".*/\1/' | sort | uniq

    # 清理目录
    # rootdir="/var/lib/kubelet"
    # 查看是否定制 root-dir `ps -ef | grep kubelet | grep root-dir`
    cd $rootdir/pods/<podid>
    ```

---

### [pod 互不连通](#1.4.2-kube-proxy)

```shell
# 查看 kube-proxy 模式
kubectl get configmaps -n kube-system kube-proxy -o yaml | grep mode
```

---

### pod 完成不自动删除

```shell
# Job 添加 TTL 机制
# kubectl explain job.spec
.spec.ttlSecondsAfterFinished: 604800 # 7d

# 删除已完成 pod
kubectl -n <namespace> get pod | awk '/Completed/ {print $1}' | while read line; do kubectl -n <namespace> delete pod $line; done
```

---

### ————————————

---

### node-NotReady

```shell
# 查看 node 日志
kubectl describe nodes <node>

# 查看 node 节点 kubelet 状态
sudo systemctl status kubelet

# 查看 kubelet 日志
sudo journalctl -xeu kubelet
```

---

### [node-DiskPressure](#1.5.1.-root-dir)

---


### ————————————

---

### terminaling

- ##### 强制删除

  ```shell
  kubectl delete <apiresource> <podname> --grace-period=0 --force

  # --grace-period=0 设置 Pod 的优雅期为 0，意味着立即终止 Pod 的运行
  # --force 强制删除
  ```

- ##### 接口删除

  ```shell
  namespace=target
  kubectl get ns $namespace -o json > $namespace.json

  # 删除 spec 与 status
  vim $namespace.json
  ...

  # 启动代理(需使用 nohup 后台运行，或者开启另一个 session)
  kubectl proxy
  # nohup kubectl proxy &

  # 调用接口删除 namespace
  curl -k -H "Content-Type: application/json" -X PUT --data-binary @$namespace.json http://localhost:8001/api/v1/namespaces/$namespace/finalize

  # 关闭代理
  # kill -9 $(ps -ux | grep "kubectl proxy" | awk '{if (NR ==1){print $2}}')
  # 或 close session
  ```

---

### nodeport 无法访问

```shell
# 查看 service 是否绑定 pod
kubectl get endpoints <svc>

# 注意 selector 一致
```

---

### CNI failed

```shell
# 查看 CNI 查看状态
kubectl get pods -n kube-system

# 查看 cni 日志
sudo journalctl -xeu kubelet | grep cni
```

---

### k8s 证书到期

```shell
# 具体所表现的错误为：
# 1. pod 无法创建；
# 2. kubectl、kube-apiserver、kube-scheduler、kube-controller-manager 日志会有 certificate、Unanthorized 关键字的错误提示

# kubesphere_v3.2 之后会自动更新 kubernetes 证书
```

```shell
# 若搭建了高可用集群，一下操作在各 master 节点上操作

# 查看证书有效期
sudo kubeadm certs check-expiration

# 备份
sudo cp -rf /etc/kubernetes /etc/kubernetes.bak.$(date +'%Y%m%d')

# 更新证书(一年)
sudo kubeadm certs renew all

# 备份旧的 admin 配置文件
# mv $HOME/.kube/config $HOME/.kube/config.bak.$(date +'%Y%m%d')
# 使用新生成的 admin 配置文件
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 重启 kubelet、kube-apiserver、kube-scheduler、kube-controller-manager
sudo systemctl restart kubelet
# docker ps | awk '/etcd/ && /pause/ {print $1}' | xargs -i docker restart {}
# docker ps | awk '/kube-apiserver/ && /pause/ {print $1}' | xargs -i docker restart {}
# docker ps | awk '/kube-scheduler/ && /pause/ {print $1}' | xargs -i docker restart {}
# docker ps | awk '/kube-controller-manager/ && /pause/ {print $1}' | xargs -i docker restart {}

# 若证书更新后，pod 还未创建，kube-apiserver、kube-scheduler、kube-controller-manager 还有相关错误日志，可将 /etc/kubernetes/manifests/*.yaml 移出后等待片刻再重新移入即可
sudo mv /etc/kubernetes/manifests/*.yaml $HOME/.
# sleep 3s
sudo mv $HOME/*.yaml /etc/kubernetes/manifests/.
```

---

### ————————————

---

## 99. scripts

- ##### super-kubectl

  ```shell
  # kubectl apply ...
  kk -a [folder|files]

  # kubectl delete ...
  kk -d [folder|files]
  ```

  ```shell
  cat > $HOME/.super-kuberctl.sh << EOF
  #!/bin/bash

  set -e

  command="apply"

  recursive() {
    local base=$1
    if [[ "${base##*.}" = "yaml" ]]; then
      kubectl $command -f $base
    elif [[ -d "$base" ]]; then
      local subs=($(ls $base))
      for sub in "${subs[@]}"; do
        recursive $base/$sub
      done
    fi
  }

  if [[ $1 = "-d" ]]; then
    command = "delete"
  fi

  for arg in $@; do
    recursive $arg
  done
  EOF

  chmod +x $HOME/.kubectl.sh

  cat >> $HOME/.zshrc << EOF
  alias kk="$HOME/.super-kuberctl.sh"
  EOF

  source $HOME/.zshrc
  ```
