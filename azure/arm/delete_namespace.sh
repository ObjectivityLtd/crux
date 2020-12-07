#!/bin/bash
deleteNamespace(){
  local cluster_namespace=$1
  if [ "$namespace" != "default" ];then
    echo "Deleting namespace $cluster_namespace"
    kubectl delete namespace "$cluster_namespace"
  fi

}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  deleteNamespace "$@"
fi