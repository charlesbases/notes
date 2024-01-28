# Prometheus

[GitHub](https://github.com/prometheus-operator/kube-prometheus) [中文文档](https://www.prometheus.wang/quickstart/) [英文文档](https://prometheus.io/docs/introduction/overview/)

------

## 1. 架构

![architecture](.pictures/architecture.png)

## 2. 安装

![compatibility](.pictures/compatibility.png)

```shell
# 若要在 Kubesphere 中集成 Prometheus，需要确保 Prometheus 相关组件与 Kubesphere 版本适配
# https://kubesphere.io/zh/docs/v3.3/faq/observability/byop
```

------

### 2.1 源码下载

```shell
version=release-0.11 && git clone -b $version https://github.com/prometheus-operator/kube-prometheus.git && mv kube-prometheus/manifests prometheus && rm kube-prometheus
```

- ##### kubesphere

  ```shell
  # 若要在 Kubesphere 中集成 Prometheus，为确保版本兼容，并且 kubesphere 能正确采集集群节点信息，建议使用 Kubesphere 提供的相关 Prometheus 组件进行修改部署

  # 查看 Kubesphere 相关 Prometheus 组件
  kubectl cp kubesphere-system/$(kubectl get pod -n kubesphere-system | grep ks-installer | awk '{print $1}'):/kubesphere/kubesphere/prometheus prometheus/kubesphere

  # version
  # cd kubesphere && ls | while read dir; do ls $dir | grep '.yaml' | while read item; do cat $dir/$item | grep 'image: ' | sed -s 's/.*image: //g' >> images.repo; done; done && cat images.repo | sort | uniq > images.repo && cat images.repo

  # uninstall prometheus
  cd kubesphere && ls -l | grep '^d' | awk '{print $NF}' | while read dir; do kubectl delete -f $dir; done

  # uninstall notification-manager
  helm uninstall notification-manager -n kubesphere-monitoring-system

  # uninstall volume
  kubectl get pvc -n kubesphere-monitoring-system | awk 'NR>1{print $1}' | while read item; do kubectl delete pvc -n kubesphere-monitoring-system $item; done
  kubectl get pv | grep 'kubesphere-monitoring-system/' | awk '{print $1}' | while read item; do kubectl delete pv $item; done

  # 注释默认 PrometheusRule
  # 注意：需保留相关 '*.rules' 规则，确保 kubesphere 能正确采集到集群节点
  cd kubesphere && ls -l | grep '^d' | awk '{print $NF}' | while read dir; do ls $dir/*prometheusRule.yaml | while read file; do sed -i -s 's/^/#&/g' $file && if [[ $(cat $file | grep '\.rules') ]]; then echo "find rules in $file"; fi; done; done

  # 注意：部署时，需要先执行 `kubectl apply -f prometheus-operator`
  ```

- ##### prometheus

  ```shell
  # 若要使用官方提供的 Prometheus，为确保 kubesphere 能正确采集集群节点信息，建议直接使用 kubesphere 提供的 prometheus 相关组件的 prometheusRule

  # 下载官方 prometheus-operator
  ...

  # 卸载 kubesphere 安装的相关 prometheus 组件
  ...

  # 拷贝 kubesphere 提供的 prometheusRule
  ls kubesphere -l | grep '^d' | awk '{print $NF}' | while read dir; do ls kubesphere/$dir/*prometheusRule.yaml | while read file; do cat $file | sed -s 's/kubesphere-monitoring-system/monitoring/g' > prometheus/${file##*/}; done; done
  ```

------

### 2.2 镜像脚本

[prom.sh](prometheus.sh)

```shell
cd kube-prometheus/manifests

vim prom.sh
...
chmod +x prom.sh
```

------

### 2.3 程序部署

```shell
# 若已部署 Kubesphere，请跳转至 '2.4.2'，在 Kubesphere 中集成 Prometheus，防止冲突。
```

------

#### 2.3.1 修改 yaml

##### 1. (pvc) grafana-deployment.yaml

```shell
# StatefulSet
sed -i -s 's/Deployment/StatefulSet/' grafana-deployment.yaml

# 升级镜像版本，防止有些 Dashboard 报错
sed -i -s 's/grafana:.*/grafana:8.5/' grafana-deployment.yaml
```

```yaml
kind: StatefulSet
apiVersion: apps/v1
...
      volumes:
-     - emptyDir: {}
-       name: grafana-storage
      - name: localtime
        hostPath:
        path: /usr/share/zoneinfo/Asia/Shanghai
...
        volumeMounts:
        - name: localtime
          mountPath: /etc/localtime
...
  volumeClaimTemplates:
    - kind: PersistentVolumeClaim
      apiVersion: v1
      metadata:
        name: grafana-storage
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 32Gi
        storageClassName: juicefs-sc
        volumeMode: Filesystem
  serviceName: grafana
```

##### 2. (pvc) prometheus-prometheus.yaml

```shell
# 若需要自动发现其他 namespace 下的 monitor, 需修改 podMonitorNamespaceSelector、serviceMonitorNamespaceSelector
```

```yaml
...
  podMonitorNamespaceSelector:
    matchLabels:
      monitoring: "true"
  serviceMonitorNamespaceSelector:
    matchLabels:
      monitoring: "true"
...
  version: 2.29.1
  volumes:
  - name: localtime
    hostPath:
      path: /usr/share/zoneinfo/Asia/Shanghai
  volumeMounts:
  - name: localtime
    mountPath: /etc/localtime
  storage:
    volumeClaimTemplate:
      spec:
        storageClassName: juicefs-sc
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 32Gi
```

##### 3. (ing) prometheus-ingress.yaml

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: prometheus-ingress
  namespace: monitoring
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
  rules:
  - host: alert.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: alertmanager-main
            port:
              number: 9093
  - host: grafana.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: grafana
            port:
              number: 3000
  - host: prom.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prometheus-k8s
            port:
              number: 9090
```

##### 4. (svc) kubernetes-serviceMonitorIngressNginx.yaml

```yaml
---
kind: Service
apiVersion: v1
metadata:
  name: ingress-nginx-metrics
  namespace: ingress-nginx
  labels:
    k8s-app: ingress-nginx
spec:
  ports:
  - name: metrics
    protocol: TCP
    port: 10254
    targetPort: metrics
  selector:
    app.kubernetes.io/component: controller
  type: ClusterIP

---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    app.kubernetes.io/name: ingress-nginx
  name: ingress-nginx
  namespace: monitoring
spec:
  endpoints:
  - interval: 30s
    port: metrics
    path: /metrics
  namespaceSelector:
    matchNames:
    - ingress-nginx
  selector:
    matchLabels:
      k8s-app: ingress-nginx
```

##### 5. (svc) kubernetes-service.yaml

```yaml
---
kind: Service
apiVersion: v1
metadata:
  name: kube-controller-manager
  namespace: kube-system
  labels:
    app.kubernetes.io/name: kube-controller-manager
spec:
  ports:
  - name: https-metrics
    protocol: TCP
    port: 10257
    targetPort: 10257
  selector:
    component: kube-controller-manager
    tier: control-plane
  type: ClusterIP

---
kind: Service
apiVersion: v1
metadata:
  name: kube-scheduler
  namespace: kube-system
  labels:
    app.kubernetes.io/name: kube-scheduler
spec:
  ports:
  - name: https-metrics
    protocol: TCP
    port: 10259
    targetPort: 10259
  selector:
    component: kube-scheduler
    tier: control-plane
  type: ClusterIP
```

##### 6. (rbac) prometheus-clusterRole.yaml

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus-k8s
  # name: kubesphere-prometheus-k8s
rules:
- apiGroups:
  - ""
  resources:
  - pods
  - services
  - endpoints
  - nodes
  - nodes/proxy
  - nodes/metrics
  verbs:
  - get
  - list
  - watch
- nonResourceURLs:
  - /metrics
  verbs:
  - get
```

##### *. PrometheusRule

```shell
# 查看 alert 文件
ls | grep 'prometheusRule.yaml'

# 注意：需保留相关 '.rules' 规则，否则会导致以下组件采集异常
#  1. kubesphere 集群节点采集失败
ls | grep 'prometheusRule.yaml' | while read file; do sed -i 's/^/#&/g' $file && if [[ $(cat $file | grep '\.rules') ]]; then echo "find rules in $file"; fi; done

# 清除报警配置，使用自定义报警
# 注意：
#   因 Prometheus 版本原因，部署时，应先验证 expr 表达式是否可执行
```

- ##### [prometheus-customPrometheusRule.yaml](prometheus-customPrometheusRule.yaml)

------

#### 2.3.2 部署清单

```shell
# 详见 2.2 镜像整理
./bash.sh apply

# 主要组件
kubectl apply -f setup(operator)
kubectl apply -f prometheus
kubectl apply -f node-exporter
kubectl apply -f kube-state-metrics
```

```shell
# 将 Prometheus 规则评估间隔设置为 1m，与 KubeSphere 3.3.0 的自定义 ServiceMonitor 保持一致。规则评估间隔应大于或等于抓取间隔

kubectl -n monitoring patch prometheus k8s --patch '{
  "spec": {
    "evaluationInterval": "1m"
  }
}' --type=merge
```

------

#### 2.3.9 错误整理

##### 1. (wan) watchdog

```
watchdog 是一个正常的报警，这个告警的作用是：如果 alermanger 或者 prometheus 本身挂掉了就发不出告警了，因此一般会采用另一个监控来监控 prometheus，或者自定义一个持续不断的告警通知，哪一天这个告警通知不发了，说明监控出现问题了。prometheus operator 已经考虑了这一点，本身携带一个 watchdog，作为对自身的监控。
```

```yaml
# kube-prometheus-prometheusRule.yaml

...
    - alert: Watchdog
      annotations:
        description: |
          This is an alert meant to ensure that the entire alerting pipeline is functional.
          This alert is always firing, therefore it should always be firing in Alertmanager
          and always fire against a receiver. There are integrations with various notification
          mechanisms that send a notification when this alert is not firing. For example the
          "DeadMansSnitch" integration in PagerDuty.
        runbook_url: https://runbooks.prometheus-operator.dev/runbooks/general/watchdog
        summary: An alert that should always be firing to certify that Alertmanager is working properly.
      expr: vector(1)
      labels:
        severity: none
...
```

##### 2. (err) connection refused

- ###### [10257] kube-controller-manager

  ```shell
  file=/etc/kubernetes/manifests/kube-controller-manager.yaml
  sudo sh -c "sed -s -i 's/--bind-address=127.0.0.1/--bind-address=0.0.0.0/g' $file"
  ```

- ###### [10259] kube-scheduler

  ```shell
  file=/etc/kubernetes/manifests/kube-scheduler.yaml
  sudo sh -c "sed -s -i 's/--bind-address=127.0.0.1/--bind-address=0.0.0.0/g' $file"

  # reset
  kubectl -n kube-system delete pods $(kubectl get pods -n kube-system | grep kube-scheduler | awk '{print $1}')
  ```

##### 3. (err) 403

```shell
# 查看 pod 绑定的 clusterRole
podname=prometheus-k8s-0
namespace=kubesphere-monitoring-system

account=$(kubectl get pod -n $namespace $podname -o jsonpath='{.spec.serviceAccountName}')
kubectl get clusterrolebindings -o wide | grep "$namespace/$account" | awk '{print $1,$2}'
```

------

### 2.4 Kubesphere

#### 2.4.1 未安装 Kubesphere

##### 1. 部署 Prometheus

```shell
# 详见 2.3 程序部署
./bash apply
```

##### 2. 集成 Kubesphere

```shell
vim cluster-configuration.yaml

...
    monitoring:
      endpoint: http://prometheus-operated.monitoring.svc:9090
...
```

------

#### 2.4.2 已安装 Kubesphere

```shell
# v3.3
# https://kubesphere.io/zh/docs/v3.3/faq/observability/byop/
```

##### 1. 卸载 kubesphere-prometheus

```shell
# clean kubesphere-system
# alertmanager、grafana、kube-state-metrics、node-exporter、prometheus-operator、etcd、kube-prometheus、kubernetes、prometheus、thanos-ruler
installer=$(kubectl get pod -n kubesphere-system -l app=ks-installer -o jsonpath='{.items[0].metadata.name}')
kubectl -n kubesphere-system exec $installer -- bash -c "ls /kubesphere/kubesphere/prometheus" | while read line; do kubectl -n kubesphere-system exec $installer -- bash -c "kubectl delete -f /kubesphere/kubesphere/prometheus/$line" 2>/dev/null; done

# clean kubesphere-monitoring-system
kebuctl -n kubesphere-monitoring-system delete svc prometheus-operated 2>/dev/null
kubectl -n kubesphere-monitoring-system delete pvc $(kubectl -n kubesphere-monitoring-system get pvc | awk '{if (NR > 1){print$1}}' | tr '\n' ' ') 2>/dev/null

# clean notification-manager
helm uninstall notification-manager -n kubesphere-monitoring-system

# clean volume
kubectl get pvc -n kubesphere-monitoring-system | awk 'NR>1{print $1}' | while read item; do kubectl delete pvc -n kubesphere-monitoring-system $item; done
kubectl get pv | grep 'kubesphere-monitoring-system/' | awk '{print $1}' | while read item; do kubectl delete pv $item; done
```

##### 2. 部署 Prometheus

- ##### 官网安装

  ```shell
  # 详见 2.3 程序部署
  ./bash apply
  ```

- ##### Kubesphere 安装

  ```shell
  # v3.3
  git clone -b release-3.3 https://github.com/kubesphere/ks-installer.git && cd ks-installer/roles/ks-monitor/files/prometheus

  # 创建 kustomization.yaml
  cat > kustomization.yaml << EOF
  kind: Kustomization
  apiVersion: kustomize.config.k8s.io/v1beta1
  namespace: monitoring
  resources:
  EOF

  find . -mindepth 2 -name "*.yaml" -type f -print | sed 's/^/- /' >> kustomization.yaml

  # (可选) 移除不必要的组件
  sed -i '/grafana\//d' kustomization.yaml

  # 部署
  kubectl apply -k .
  ```

##### 3. 集成 Prometheus

```shell
kubectl get cm -n kubesphere-system kubesphere-config -o yaml | sed -s 's/prometheus-operated.kubesphere-monitoring-system.svc:9090/prometheus-operated.monitoring.svc:9090/' | kubectl apply -f -
```

```shell
kubectl edit cm -n kubesphere-system kubesphere-config

...
    monitoring:
      endpoint: http://prometheus-operated.monitoring.svc:9090
...

# restart
kubectl rollout restart -n kubesphere-system deployment ks-controller-manager
```

------

## 3. Exporter

```http
https://prometheus.io/docs/instrumenting/exporters/
```

### 3.1. Nats

```shell
docker pull natsio/prometheus-nats-exporter:0.10.1
```

```yaml
---
kind: StatefulSet
apiVersion: apps/v1
metadata:
  name: nats
...
      containers:
      - name: metrics
        image: 'natsio/prometheus-nats-exporter:0.9.3'
        args:
        - '-connz'
        - '-routez'
        - '-subz'
        - '-varz'
        - '-prefix=nats'
        - '-use_internal_server_id'
        - '-DV'
        - 'http://localhost:8222/'
        ports:
        - name: metrics
          containerPort: 7777
          protocol: TCP
        resources:
          limits:
            cpu: '1'
            memory: 1Gi
          requests:
            cpu: '0.5'
            memory: 512Mi
        imagePullPolicy: IfNotPresent
...
```

### 3.2. Kafka

```shell
docker pull danielqsj/kafka-exporter:v1.6.0
```

```yaml
---
kind: StatefulSet
apiVersion: apps/v1
metadata:
  name: kafka
...
      containers:
      - name: metrics
        image: 'danielqsj/kafka-exporter:v1.6.0'
        args:
        - '--kafka.server=localhost:9092'
        ports:
        - name: metrics
          containerPort: 9308
          protocol: TCP
        resources:
          limits:
            cpu: '1'
            memory: 1Gi
          requests:
            cpu: '0.5'
            memory: 512Mi
        imagePullPolicy: IfNotPresent
...
```

### 3.3. Redis

```shell
docker pull oliver006/redis_exporter:alpine
```

```yaml
---
kind: StatefulSet
apiVersion: apps/v1
metadata:
  name: kafka
...
      containers:
      - name: metrics
        image: 'oliver006/redis_exporter:alpine'
        args:
        - '--redis.addr=redis://localhost:6379'
        - '--redis.user=default'
        - '--redis.password='
        ports:
        - name: metrics
          containerPort: 9121
          protocol: TCP
        resources:
          limits:
            cpu: '1'
            memory: 1Gi
          requests:
            cpu: '0.5'
            memory: 512Mi
        imagePullPolicy: IfNotPresent
...
```

### 3.4. Mysql

```shell
docker pull prom/mysqld-exporter:v0.14.0
```

```yaml
---
kind: StatefulSet
apiVersion: apps/v1
metadata:
  name: mysql
...
      containers:
      - name: metrics
        image: 'prom/mysqld-exporter:v0.14.0'
        env:
        - name: DATA_SOURCE_NAME
          value: "user:password@(localhost:3306)/database"
        ports:
        - name: metrics
          containerPort: 9104
          protocol: TCP
        resources:
          limits:
            cpu: '1'
            memory: 1Gi
          requests:
            cpu: '0.5'
            memory: 512Mi
        imagePullPolicy: IfNotPresent
...
```

### 3.5. Postgresql

```shell
docker pull prometheuscommunity/postgres-exporter:v0.11.1
```

```yaml
---
kind: StatefulSet
apiVersion: apps/v1
metadata:
  name: postgresql
...
      containers:
      - name: metrics
        image: 'prometheuscommunity/postgres-exporter:v0.11.1'
        env:
        - name: DATA_SOURCE_NAME
          value: "postgresql://postgres:postgres@localhost:5432/postgres?sslmode=disable"
        ports:
        - name: metrics
          containerPort: 9187
          protocol: TCP
        resources:
          limits:
            cpu: '1'
            memory: 1Gi
          requests:
            cpu: '0.5'
            memory: 512Mi
        imagePullPolicy: IfNotPresent
...
```

------

## 4. Monitor

### 4.1. kubelet

### 4.2. kube-apiserver

### 4.3. kube-scheduler

### 4.4. kube-controller-manager

### 4.5. calico

#### 1. felixconfigurations

```shell
# 修改 calico felix
kubectl edit felixconfigurations

...
  spec:
    prometheusMetricsEnabled: true
...
```

#### 2. calico-node

```shell
# 开放 daemonset/calico-node 端口
if [[ ! $(kubectl get -n kube-system daemonsets calico-node -o yaml | grep "name: http-metrics") ]]; then
  kubectl get -n kube-system daemonsets calico-node -o yaml | sed '/^        name: calico-node/a\        ports:\n        - name: http-metrics\n          hostPort: 9091\n          containerPort: 9091' | kubectl apply -f -
fi
```

```shell
kubectl edit -n kube-system daemonsets calico-node

...
spec:
  template:
    spec:
      containers:
      - name: calico-node
        ports:
        - name: http-metrics
          hostPort: 9091
          containerPort: 9091
...
```

#### 3. monitor

```yaml
# calico-podMonitor.yaml
---
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  labels:
    k8s-app: calico-node
  name: calico
  namespace: monitoring
spec:
  namespaceSelector:
    matchNames:
    - kube-system
  podMetricsEndpoints:
  - port: http-metrics
    path: /metrics
    interval: 15s
  selector:
    matchLabels:
      k8s-app: calico-node
```

------

### 4.6. ingress

#### 1. metrics

```shell
# 开放 metrics 端口
if [[ ! $(kubectl get -n ingress-nginx deployments ingress-nginx-controller -o yaml | grep "name: metrics") ]]; then
  kubectl get -n ingress-nginx deployments ingress-nginx-controller -o yaml | sed '/ports:/a\        - name: metrics\n          containerPort: 10254' | kubectl apply -f -
fi
```

```shell
kubectl get -n ingress-nginx deployments ingress-nginx-controller -o yaml | sed '/ports:/a\        - name: metrics\n          containerPort: 10254' | kubectl apply -f -
```

#### 2. monitor

```yaml
# ingress-nginx-serviceMonitor.yaml
---
kind: Service
apiVersion: v1
metadata:
  name: ingress-nginx-metrics
  namespace: ingress-nginx
  labels:
    k8s-app: ingress-nginx
spec:
  ports:
    - name: metrics
      protocol: TCP
      port: 10254
      targetPort: metrics
  selector:
    app.kubernetes.io/component: controller
  type: ClusterIP

---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    app.kubernetes.io/name: ingress-nginx
  name: ingress-nginx
  namespace: monitoring
spec:
  endpoints:
  - interval: 30s
    port: metrics
    path: /metrics
  namespaceSelector:
    matchNames:
    - ingress-nginx
  selector:
    matchLabels:
      k8s-app: ingress-nginx
```

```shell
# 日志查看
kubectl logs -n ingress-nginx $(kubectl get -n ingress-nginx pods | grep ingress-nginx-controller | awk '{print $1}')

# 查看标签
kubectl get -n ingress-nginx svc ingress-nginx-controller -o yaml
```

### 4.9. scripts

#### 1. [monitor](monitor.sh)

------

## 99. 问题排查

- ##### serviceMonitor 绑定不了 service

  ```shell
  # serviceMonitor 可绑定任意 namespace 下匹配 labels 的 service，如需指定 namespace，可通过 namespaceSelector 配置

  ...
    namespaceSelector:
  #   any: "true"
      matchNames:
      - my-namespace
  ...
  ```

- ##### 新增 monitor 在 prometheus 上不显示

  ```shell
  # prometheus-operator 在安装时默认只会自动发现 "default", "kube-system", "monitoring" 名称空间下新建的 PodMonitor、ServiceMonitor
  ```

  ```shell
  # 查看 prometheus-configuration。
  kubectl -n monitoring exec prometheus-k8s-0 -c prometheus -- sh -c "cat /etc/prometheus/config_out/prometheus.env.yaml | grep 'job_name: serviceMonitor'"
  ```

  ```shell
  # 若有相关 monitor，则 monitor 未绑定相关 service 或 pod。

  ...
  kind: ServiceMonitor
  spec:
    endpoints:
    - port: {service.spec.ports[0].name}
      path: "/metrics"
      interval: 15s
    selector:
      matchLabels:
        {service.metadata.labels}
  ...

  ```

  ```shell
  # 若没有相关 monitor，则 prometheus-operator 未自动发现新加的 monitor。需配置相关 namespace 的 selector

  # 添加节点标签
  for ns in default monitoring kube-system; do kubectl label namespaces $ns monitoring="true"; done

  kubectl edit -n monitoring prometheuses k8s

  ...
    podMonitorNamespaceSelector:
      matchLabels:
        monitoring: "true"
    serviceMonitorNamespaceSelector:
      matchExpressions:
      - key: kubernetes.io/namespace
        operator: In
        values:
        - "kube-system"
        - "monitoring"
        - "default"
  ...
  ```

  ```shell
  # 重新加载 prometheus
  kubectl rollout restart -n monitoring statefulset prometheus-k8s
  ```
