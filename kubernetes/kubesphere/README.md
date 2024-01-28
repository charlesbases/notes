[GitHub](https://github.com/kubesphere/kubesphere) [中文文档](https://kubesphere.io/zh/docs/v3.3/faq/observability/byop)

------

------

## 1. 安装

- ##### minimal

  ```shell
  # https://kubesphere.io/zh/docs/v3.3/quick-start/minimal-kubesphere-on-k8s/
  ```

- ##### offline

  ```shell
  # https://kubesphere.io/zh/docs/v3.3/installing-on-kubernetes/on-prem-kubernetes/install-ks-on-linux-airgapped/
  ```

------

```shell
version=v3.3.2

# yaml
wget https://github.com/kubesphere/ks-installer/releases/download/$version/kubesphere-installer.yaml
wget https://github.com/kubesphere/ks-installer/releases/download/$version/cluster-configuration.yaml

# images list
wget -O images.txt https://github.com/kubesphere/ks-installer/releases/download/$version/images-list.txt

# installation-tool.sh
wget -O installation.sh https://github.com/kubesphere/ks-installer/releases/download/v3.3.1/offline-installation-tool.sh
```

```shell
# kubesphere 相关镜像地址为 ${repository}/kubesphere/*
```

------

## 2. 访问控制

```shell
# 名词解释

# 项目 -- namespace
# 企业空间 -- 多个 namespace 的集合
```

```shell
1. 创建企业空间: 
   平台管理 - 访问控制 - 企业空间 - 创建

2. 企业空间配置: 
   平台管理 - 集群管理 - 项目 - 分配企业空间

3. 创建访问用户: 
   平台管理 - 访问控制 - 用户 - 创建

4. 添加企业用户: 
   企业空间 - 企业空间设置 - 企业空间成员 - 添加

5. 移除企业空间下的项目
# 企业空间下的项目，在 kubernetes 中是根据 namespace 下的 label 相关联

# 查看项目与企业空间关联表
# kubectl get namespace --show-labels | grep -- kubesphere.io/workspace

# 查看项目所绑定的企业空间
# kubectl get namespace map --show-labels | grep -- 'kubesphere.io/workspace'

# 查看企业空间下所有的项目
# kubectl get namespace --show-labels | grep -- kubesphere.io/workspace=map

# 移除企业空间下的项目
# kubectl label namespace <namespace> kubesphere.io/workspace-
```

------

## 99. Error

- ##### node_exportes: 9100 address already in use

  ```shell
  # 方法一: 修改 kubesphere-configuration.yaml
  ···
      node_exporter:
        port: 9100
  ···
  
  # 方法二: 修改 Kubernetes 资源
  kubectl edit -n kubesphere-monitoring-system ds node-exporter
  kubectl edit -n kubesphere-monitoring-system svc node-exporter
  ```

  

