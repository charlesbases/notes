```shell
# namespace
kubectl create namespace devops
```

------

## 1. Tekton

### 1.1. install

#### 1.1.1. pipeline

```shell
# 查看 tekton-pipeline 支持的 Kubernetes 版本
# https://github.com/tektoncd/pipeline

version=v0.46.0
wget -O - https://storage.googleapis.com/tekton-releases/pipeline/previous/$version/release.yaml >> tekton.yaml
```

#### 1.1.2. dashboard

```shell
# 查看 tekton-dashboard 支持的 tekton-pipeline 版本
# https://github.com/tektoncd/dashboard/releases

version=v0.34.0
wget -O https://github.com/tektoncd/dashboard/releases/download/$version/release.yaml >> tekton.yaml
```

---

### 1.2. documents

```shell
# 注意：Task 和 Pipeline 需要手动创建，TaskRun 和 PipelineRun 可通过 WebUI 创建
```

#### 1.2.1 api-resources

[demo](./tekton)

```shell
# 一条 tekton pipeline 的执行或者部署流程为：
#	1. kubectl -n tekton-pipelines apply -f common.yaml
# 	2. kubectl -n tekton-pipelines apply -f task.yaml
#	3. kubectl -n tekton-pipelines apply -f pipeline.yaml
#	4. 登录 tekton.daskboard
#	5. 根据 Pipeline 创建 PipelineRun, 然后自动创建 TaskRun 执行流程

# 注意：
#	1. TaskRun 和 PipelineRun 可通过 yaml 手动创建，但为了方便以及减少流程，推荐使用 tekton.daskboard 自动创建
#	2. Task 中定义的 resources、params 需要在 Pipeline 中指定字段对应，然后在创建 PipelineRun 中输入
```

##### 1. Secret

```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: devops
  namespace: tekton-pipelines
secrets:
  - name: gitlab-ssh
  - name: dockerconfig
```

- ###### gitlab

  ```shell

  ```

  ```yaml
  ---
  apiVersion: v1
  kind: Secret
  metadata:
    name: gitlab-ssh
    namespace: tekton-pipelines
    annotations:
      tekton.dev/git-0: 10.63.1.35:9222
  type: kubernetes.io/ssh-auth
  stringData:
    ssh-privatekey: <private-key> # $(cat ~/.ssh/id_rsa)
    # konw_hosts: <konw_hosts>

  ```

- ###### docker

  ```shell
  # 根据 '.docker/config.json' 创建 secret
  kubectl -n tekton-pipelines create secret generic dockerconfig --from-file=.dockerconfigjson=$HOME/.docker/config.json --type=kubernetes.io/dockerconfigjson
  ```

  ```yaml
  apiVersion: v1
  kind: Secret
  metadata:
    name: dockerconfig
    namespace: tekton-pipelines
  type: kubernetes.io/dockerconfigjson
  data:
    .dockerconfigjson: ewoJImF1dGhzIjogewoJCSIxMC42NC4xMC4yMTA6MTAwODMiOiB7CgkJCSJhdXRoIjogIlkyRnlZbTl1WkRwamFHVjVkVzR6TWpFaCIKCQl9Cgl9Cn0=
  ```

- ##### kubeconfig

  ```shell
  # 根据 '$HOME/.kube/config' 创建 kubeconfig
  kubectl -n tekton-pipelines create configmap kubeconfig --from-file=$HOME/.kube/config
  ```

##### 2. Task

*Task 为构建任务，是 Tekton 中不可分割的最小单位，正如同 Pod 在 Kubernetes 中的概念一样。在 Task 中，可以有多个 Step，每个 Step 由一个 Container 来执行。*

*可以在 Task 中定义 resources、params 参数，运行时在 TaskRun 中指定*

```yaml
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: environment
  namespace: tekton-pipelines
data:
  GOOS: 'linux'
  GOARCH: 'amd64'
  CGO_ENABLED: '0'
  GO111MODULE: 'on'
  GOPATH: '/go'
  GOPROXY: 'http://10.61.130.5:8081/nexus/repository/proxy-goproxy/,direct'

---
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: backend
  namespace: tekton-pipelines
  labels:
    app: backend
spec:
  params:
    - name: repository
      type: string
    - name: alpine
      type: string
    - name: tag
      type: string
  resources:
    inputs:
      - name: backend
        type: git
  steps:
    - name: go-build
      image: '10.64.10.210:10083/golang:1.20'
      workingDir: /workspace/backend/backend
      envFrom:
        - configMapRef:
            name: environment
      command:
        - go
      args:
        - build
        - -o
        - main
        - .
      volumeMounts:
        - name: localtime
          mountPath: /etc/localtime
    - name: docker-build
      image: '10.64.10.210:10083/docker:git'
      workingDir: /workspace/backend
      command:
        - docker
      args:
        - build
        - --network=host
        - --build-arg
        - REGISTRY="$(params.repository)"
        - --build-arg
        - ALPINE_TAG="$(params.alpine)"
        - -f
        - ./ci/srv/Dockerfile
        - --tag
        - 'task_hub_srv:$(params.tag)'
        - .
      volumeMounts:
        - name: localtime
          mountPath: /etc/localtime
  volumes:
    - name: localtime
      hostPath:
        path: /usr/share/zoneinfo/Asia/Shanghai

```

##### 3. TaskRun

*[PipelineRun](#5.-PipelineRun) 被创建出来后，会对应 Pipeline 里面的 Task 创建各自的 TaskRun。一个 TaskRun 控制一个 Pod，Task 中的 Step 对应 Pod 中的 Container。当然，TaskRun 也可以单独被创建。*

##### 4. Pipeline

*Pipeline 由一个或多个 Task 组成。在 Pipeline 中，用户可以定义这些 Task 的执行顺序以及依赖关系来组成 DAG（有向无环图）*

```yaml
---
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: backend
  namespace: tekton-pipelines
  labels:
    app: backend
spec:
  params:
    - name: repository
      type: string
      default: "10.64.10.210:10083"
    - name: alpine
      type: string
      default: "alpine:3.15.4"
    - name: tag
      type: string
      default: "latest"
  resources:
    - name: backend
      type: git
  tasks:
    - name: backend
      taskRef:
        name: backend
      params:
        - name: repository
          value: "$(params.repository)"
        - name: alpine
          value: "$(params.alpine)"
        - name: tag
          value: "$(params.tag)"
      resources:
        inputs:
          - name: backend
            resource: backend

```

##### 5. PipelineRun

*PipelineRun 是 [Pipeline](#4.-Pipeline) 的实际执行产物，当用户定义好 Pipeline 后，可以通过创建 PipelineRun 的方式来执行流水线，并生成一条流水线记录。*

##### 6. PipelineResource

*PipelineResource 代表着一系列的资源，主要承担作为 Task 的输入或者输出的作用*

*推荐在 TaskRun 中定义 PipelineResource*

*它有以下几种类型：*

*1. git：代表一个 git 仓库，包含了需要被构建的源代码。将 git 资源作为 Task 的 Input，会自动 clone 此 git 仓库。(使用 git 拉取代码时，存在安全和私有仓库安全的问题，需要配置相关的 '[secrets/serviceaccount](#1.-Secret)')*

```yaml
apiVersion: tekton.dev/v1alpha1
kind: PipelineResource
metadata:
  name: backend
  namespace: tekton-pipelines
spec:
  params:
    - name: url
      value: 'ssh://git@10.63.1.35:9222/zhiming.sun/backend.git'
    - name: revision
      value: 'develop' # branch or tag or commit hash
  type: git
```

*2. pullRequest：表示来自配置的 url（通常是一个 git 仓库）的 pull request 事件。将 pull request 资源作为 Task 的 Input，将自动下载 pull request 相关元数据的文件，如 base/head commit、comments 以及 labels。*

*3. image：代表镜像仓库中的镜像，通常作为 Task 的 Output，用于生成镜像。*

```yaml
---
apiVersion: tekton.dev/v1alpha1
kind: PipelineResource
metadata:
  labels:
    app: backend
  name: app
  namespace: tekton-pipelines
spec:
  type: image
  params:
  - name: url
    value: '<repo>/csmp/cloud/platform/app'
```

*4. cluster：表示一个除了当前集群外的 Kubernetes 集群。可以使用 Cluster 资源在不同的集群上部署应用。*

*5. storage：表示 blob 存储，它包含一个对象或目录。将 Storage 资源作为 Task 的 Input 将自动下载存储内容，并允许 Task 执行操作。目前仅支持 GCS。*

*6. cloud event：会在 TaskRun z执行完成后发送事件信息（包含整个 TaskRun） 到指定的 URI 地址，在与第三方通信的时候十分有用。*

------

## 2. ArgoCD

### 2.1. install

#### 2.1.1. argocd

```shell
# argocd 所支持的 kubernetes 版本为 N, N-1, N-2。例如 argocd_v2.6 支持 kubernetes_v1.26、kubernetes_v1.25、kubernetes_v1.24

# github
# https://github.com/argoproj/argo-cd

# documents
# https://argo-cd.readthedocs.io/en/stable
```

- ##### helm

  ```shell
  version=argo-cd-5.29.1
  wget -O argocd.tgz https://github.com/argoproj/argo-helm/releases/download/$version/$version.tgz
  tar -zxvf argocd.tgz && rm -rf argocd.tgz
  ```

- ##### kubectl

  ```shell
  version=stable
  wget -O argocd.yaml https://raw.githubusercontent.com/argoproj/argo-cd/$version/manifests/install.yaml
  ```

---

### 2.2. documents

#### 2.2.1. resources

##### 1. cluster

*Kubernetes cluster*

```shell
# 查看目标集群 NAME
kubectl config get-contexts | awk 'NR>1{print $2}' # kubernetes-admin@kubernetes

# login
argocd --insecure login localhost:8080 --username=admin --password=12345678

# cluster
argocd cluster add <KUBERNETES_NAME> --name <ALIAS_NAME> --kubeconfig .kube/cluster-dev -y
```

#### 2.2.2. api-resources

##### 1. AppProject

*项目名称。这是 ArgoCD 中应用程序的一种组织方式，类似于 kubernetes.namespace*

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: app
  namespace: argocd
spec:
  sourceRepos:
  - '*'
  destinations:
  # 目标集群 namespace
  - namespace: '*'
	# 目标集群 url
    server: '*'
    # 是否禁用目标集群的 SSL/TLS 验证
    insecure: 'true'
  clusterResourceWhitelist:
  - group: '*'
    kind: '*'
```

##### 2. Application

*应用程序*

```yaml
kind: Application
apiVersion: argoproj.io/v1alpha1
metadata:
  name: dev-auth
  namespace: argocd
  labels:
    env: dev
    app: auth
spec:
  # 项目名称
  project: map
  source:
  	# 应用程序路径
    repoURL: 'http://10.63.1.35/cloud/platform/task_hub.git'
    # 分支
    targetRevision: 'develop'
    # 路径
    path: 'manifests/dev'
  destination:
  	# 集群 url
    server: 'https://10.63.3.11:6443'
    # 部署到集群的目标命名空间
    namespace: 'map'
  syncPolicy:
    automated:
      prune: true
```

#### 2.2.3. notifications

```shell

```

------

## 3. Getting Started

```shell
# 注意: 因 tekton 和 argocd 的 yaml 缩进方式不同，下载完官方文件后，需要粘贴再复制(argocd.yaml)，统一格式化为 ide 缩进方案 "indent sequence value", 才可执行脚本进行 yaml 修改

# 备份原始 yaml
sed -i '1i ---' tekton.yaml && ls *.yaml | while read file; do cp $file $file.bak; done

# 修改镜像拉取策略
sed -i 's/imagePullPolicy: Always/imagePullPolicy: IfNotPresent/g' *.yaml
```

---

### 3.1. tekton

```shell
# 注释掉 'kind: Namespace', 改为手动创建。防止卸载时 namespace 删除失败
# awk '/^kind: Namespace/ {print FILENAME":"NR} ' *.yaml
awk '/^---/ {if (focus) { print (above+1)"," (NR-1)}; above=NR; focus=""; next} /^kind: Namespace/ {focus=NR}' tekton.yaml | while read line; do sed -i "$line {/^[^#]/ s/^/# /}" tekton.yaml; done
```

```shell
# 调整 "-shell-image" 镜像 hash
awk '/-shell-image/ || /-gsutil-image/ {print FILENAME":"FNR}' tekton.yaml

# 移除镜像 sha256
sed -i 's/@sha256[^"]*//g' tekton.yaml

# 镜像下载
./dockerhub.sh pull
```

- ##### tekton-dashboard

  ```shell
  awk '/^kind: Deployment/ || /^kind: StatefulSet/ { line=FNR } /serviceAccountName: tekton-dashboard/ { if ( line ) { print FILENAME":"line; exit } }' tekton.yaml

  # localtime
  ...
            volumeMounts:
              - mountPath: /etc/localtime
                name: localtime
  ...
        volumes:
          - hostPath:
              path: /usr/share/zoneinfo/Asia/Shanghai
              type: ""
            name: localtime
  ...
  ```

```shell
# namespace
grep '^  namespace: ' tekton.yaml | sort | uniq | awk '{gsub(/ /, ""); sub(/namespace:/, ""); print}' | while read line; do kubectl create namespace $line; done
```

```shell
# apply
kubectl apply -f tekton.yaml
```

---

### 3.2. argocd

```shell
# 禁用 argocd-notifications
# awk '/^---/ {if (focus) { print (above+1)"," (NR-1)}; above=NR; focus=""; next} /name: argocd-notifications/ {focus=NR}' argocd.yaml | while read line; do sed -i "$line {/^[^#]/ s/^/# /}" argocd.yaml; done
```

```shell
# 禁用 tls
# argocd-server
# awk '/ARGOCD_SERVER_INSECURE/ {print FILENAME":"FNR}' argocd.yaml
sed -i 's/\(.*\)- argocd-server/\1- argocd-server\n\1- --insecure/' argocd.yaml

# argocd-repo-server
# awk '/ARGOCD_REPO_SERVER_DISABLE_TLS/ {print FILENAME":"FNR}' argocd.yaml
# sed -i 's/\(.*\)- argocd-repo-server/\1- argocd-repo-server\n\1- --disable-tls/' argocd.yaml
```

```shell
# 镜像下载
./dockerhub.sh pull
```

- ##### argocd-server

  ```shell
  awk '/^kind: Deployment/ || /^kind: StatefulSet/ { line=FNR } /serviceAccountName: argocd-server/ { if ( line ) { print FILENAME":"line; exit } }' argocd.yaml
  ```

  ```shell
  # 修改 deployment 为 statefulset
  awk '/^kind: Deployment/ || /^kind: StatefulSet/ { line=FNR } /serviceAccountName: argocd-server/ { if ( line ) { print line; exit } }' argocd.yaml | while read line; do sed -i "$line s/Deployment/StatefulSet/" argocd.yaml; done; awk '/^kind: Deployment/ || /^kind: StatefulSet/ { line=FNR } /serviceAccountName: argocd-server/ { if ( line ) { print FILENAME":"line; exit } }' argocd.yaml

  # 添加 serviceName
  ...
  spec:
    serviceName: argocd-server
  ...
  ```

  ```shell
  # volumes.data (pvc)
  awk '/volumeMounts/ { line=FNR } /serviceAccountName: argocd-server$/ { if ( line ) { print FILENAME":"line; exit } } ' argocd.yaml

  ...
            volumeMounts:
  #            - mountPath: /home/argocd
  #              name: plugins-home
              - mountPath: /home/argocd
                name: data
  ...
        volumes:
  #        - emptyDir: { }
  #          name: plugins-home
    serviceName: argocd-server
    volumeClaimTemplates:
      - kind: PersistentVolumeClaim
        apiVersion: v1
        metadata:
          name: data
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 1Ti
          storageClassName: juicefs-sc
          volumeMode: Filesystem
  ...
  ```

  ```shell
  # volumes.localtime & volumes.kubeconfig
  awk '/volumeMounts/ { line=FNR } /serviceAccountName: argocd-server$/ { if ( line ) { print FILENAME":"line; exit } } ' argocd.yaml

  ...
            volumeMounts:
              - mountPath: /etc/localtime
                name: localtime
              - mountPath: /home/argocd/.kube
                name: kubeconfig
  ...
        volumes:
          - name: localtime
            hostPath:
              path: /usr/share/zoneinfo/Asia/Shanghai
          - name: kubeconfig
            configMap:
              name: kubeconfig
              defaultMode: 420
  ...
  ```

- ##### secret

  ```shell
  # 修改 argocd admin 默认密码为 '12345678'
  sed -i "/^  name: argocd-secret/a\stringData:\n  admin.password: \"\$2a\$10\$ZlLYZpTmSOtJEvgdQp6qsuVysPrneGq4f7P1e0C6ch51ro5lJc8NW\"\n  admin.passwordMtime: \"$(date +%FT%T)\"" argocd.yaml
  ```

```shell
# namespace
kubectl create namespace argocd

# kubeconfig
kubectl create configmap kubeconfig --from-file ~/.kube/config -n argocd

# apply
kubectl apply -n argocd -f argocd.yaml
```

---

### 3.3. [ingress](./devops.yaml)

------

## 4. Error

### 1. Tekton

------

### 2. ArgoCD

```shell
# argocd-ui
# username: admin

# 自动登录
kubectl -n argocd exec $(kubectl -n argocd get pod | grep argocd-server | awk '{print $1}') -- bash -c "echo 'alias l=\"ls -alh\"' > .bashrc; echo 'argocd --insecure login localhost:8080 --username=admin --password=12345678' >> .bashrc"

# 默认密码
kubectl -n argocd get secrets argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo

# 修改密码
kubectl -n argocd exec -it $(kubectl -n argocd get pod | grep argocd-server | awk '{print $1}') -- bash
# user=admin; password=<currentPassword>; newPassword=12345678
# argocd --insecure login localhost:8080 --username=$user --password=$password
# argocd account update-password --current-password=$password --new-password=$newPassword

# 重置密码
# generating a bcrypt hash
kubectl -n argocd exec -it $(kubectl -n argocd get pod | grep argocd-server | awk '{print $1}') -- bash -c 'argocd account bcrypt --password <password>' && echo
# to apply the new password hash
kubectl -n argocd patch secret argocd-secret -p '{"stringData": {"admin.password": "<password-hash>", "admin.passwordMtime": "'$(date +%FT%T%Z)'"}}'
```
