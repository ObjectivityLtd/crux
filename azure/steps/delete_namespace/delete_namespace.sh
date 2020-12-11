#!/bin/bash
delete_namespace() { #public: deletes namespace together with all pods inside
  local _cluster_namespace=$1
  if [ "$_cluster_namespace" != "default" ]; then
    echo "Deleting namespace $_cluster_namespace"
    kubectl delete namespace "$_cluster_namespace"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  delete_namespace "$@"
fi
