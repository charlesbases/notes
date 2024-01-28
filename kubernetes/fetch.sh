#!/usr/bin/env bash

set -e

versionCalico=v3.23
versionNginxIngress=v1.5.1
versionMetricsServer=v0.6.3

plugins=(
# cni-calico
"https://docs.projectcalico.org/$versionCalico/manifests/calico.yaml calico.yaml"
# metrics-server
"https://github.com/kubernetes-sigs/metrics-server/releases/download/$versionMetricsServer/components.yaml metrics.yaml"
# nginx-ingress
"https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-$versionNginxIngress/deploy/static/provider/cloud/deploy.yaml nginx_ingress.yaml"
)

for (( i = 0; i < ${#plugins[@]}; i++ )); do
  args=(${plugins[i]})

  wget -O ${args[1]} ${args[0]}
done
