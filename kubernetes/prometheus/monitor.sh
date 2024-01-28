#!/usr/bin/env bash

prometheusNameSpace=kubesphere-monitoring-system

help() {
  echo """
usage:
  ./$(basename $0) [options] command

options:
  -A    show all monitor in the 'prometheus.env.yaml'
  -n    the namespace scope for this CLI request
  -l    selector label to filter on

commands:
  pod   generate podMonitor
  svc   generate serviceMonitor
"""
  exit
}

podMonitor() {
  for namespace in "${namespaces[@]}"; do
    mkdir -p monitor/podMonitor/$namespace >/dev/null 2>&1
    echo -e "\033[35mnamespace in $namespace\033[0m"

    kubectl get pod -n $namespace $label | awk '{if (NR > 1){print $1}}' | while read item; do
      echo -e "\033[32mfind pod/$item\033[0m"

      local labels=$(kubectl get pod -n $namespace $item -o jsonpath='{.metadata.labels}')
      if [[ ! $labels ]]; then
        echo "Warn: not found labels in the pod/$item"
        continue
      fi

      local refname=$(kubectl get pod -n $namespace $item -o jsonpath='{.metadata.ownerReferences[0].name}')

      case $(kubectl get pod -n $namespace $item -o jsonpath='{.metadata.ownerReferences[0].kind}') in
        ReplicaSet)
        refname=${refname%-*}
        ;;
        DaemonSet)
        # do nothing
        ;;
        StatefulSet)
        refname=$(kubectl get pod -n $namespace $item -o jsonpath='{.metadata.name}')
        ;;
        *)
        continue
        ;;
      esac

      # default podMonitorPort
      podMonitorPort=$(kubectl get pod -n $namespace $item -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
      if [[ $(kubectl describe pod -n $namespace $item | grep '  Port' | grep -v '<none>' | awk 'END {print NR}') -gt 1 ]] || \
         [[ $(kubectl describe pod -n $namespace $item | grep '  Ports') ]]; then
        podMonitorPort="metrics"
      fi

      cat > monitor/podMonitor/$namespace/$refname.json << EOF
{
  "apiVersion": "monitoring.coreos.com/v1",
  "kind": "PodMonitor",
  "metadata": {
    "name": "$refname",
    "namespace": "$prometheusNameSpace",
    "labels": $labels
  },
  "spec": {
    "podMetricsEndpoints": [
      {
        "port": "$podMonitorPort",
        "path": "/metrics",
        "interval": "15s"
      }
    ],
    "namespaceSelector": {
      "matchNames": [
        "$namespace"
      ]
    },
    "selector": {
      "matchLabels": $labels
    }
  }
}
EOF
    done
  done
}

serviceMonitor() {
  for namespace in "${namespaces[@]}"; do
    mkdir -p monitor/serviceMonitor/$namespace >/dev/null 2>&1
    echo -e "\033[35mnamespace in $namespace\033[0m"

    kubectl get svc -n $namespace $label | awk '{if (NR > 1){print $1}}' | while read item; do
      echo -e "\033[32mfind service/$item\033[0m"

      local labels=$(kubectl get svc -n $namespace $item -o jsonpath='{.metadata.labels}')
      if [[ ! $labels ]]; then
        echo "Warn: not found labels in the service/$item"
        continue
      fi

      # default serviceMonitorPort
      serviceMonitorPort=$(kubectl get svc -n $namespace $item -o jsonpath='{.spec.ports[0].name}')
      if [[ $(kubectl describe svc -n $namespace $item | grep -w 'Port:' | awk 'END {print NR}') -gt 1 ]]; then
        serviceMonitorPort="metrics"
      fi

      cat > monitor/serviceMonitor/$namespace/$item.json << EOF
{
  "apiVersion": "monitoring.coreos.com/v1",
  "kind": "ServiceMonitor",
  "metadata": {
    "name": "$item",
    "namespace": "$prometheusNameSpace",
    "labels": $labels
  },
  "spec": {
    "endpoints": [
      {
        "port": "$serviceMonitorPort",
        "path": "/metrics",
        "interval": "15s"
      }
    ],
    "namespaceSelector": {
      "matchNames": [
        "$namespace"
      ]
    },
    "selector": {
      "matchLabels": $labels
    }
  }
}
EOF
    done
  done
}

showMonitor() {
  if [[ $(kubectl get -n $prometheusNameSpace pod -l app.kubernetes.io/name=prometheus) ]]; then
    podName=$(kubectl get -n $prometheusNameSpace pod -l app.kubernetes.io/name=prometheus | awk 'NR==2 {print $1}')

    echo -e "\033[32mpodMonitor\033[0m"
    kubectl -n $prometheusNameSpace exec $podName -c prometheus -- sh -c "cat /etc/prometheus/config_out/prometheus.env.yaml | grep 'job_name: podMonitor'" 2>/dev/null

    echo -e "\033[32mserviceMonitor\033[0m"
    kubectl -n $prometheusNameSpace exec $podName -c prometheus -- sh -c "cat /etc/prometheus/config_out/prometheus.env.yaml | grep 'job_name: serviceMonitor'" 2>/dev/null
  else
    echo "Error: prometheus not running in $prometheusNameSpace namespace."
  fi
}

namespaces=()
label=

while getopts ":n:l:hA" opt; do
  case $opt in
    n)
    namespaces[${#namespaces[@]}]=$OPTARG
    ;;
    l)
    label="-l $OPTARG"
    ;;
    h)
    help
    exit
    ;;
    A)
    showMonitor
    exit
    ;;
    ?)
    echo "Error: invalid flag: '-$OPTARG'"
    echo "See './$(basename $0) -h' for usage."
    exit
    ;;
  esac
done

if [[ ${#namespaces[@]} -eq 0 ]]; then
  echo "Error: must specify one of -n"
  echo "See './$(basename $0) -h' for usage."
  exit
fi

set -e

shift $(($OPTIND - 1))
case $1 in
  svc)
  serviceMonitor
  ;;
  pod)
  podMonitor
  ;;
  *)
  echo "Error: invalid command: '$1'"
  echo "See '$0 -h' for usage."
  ;;
esac
