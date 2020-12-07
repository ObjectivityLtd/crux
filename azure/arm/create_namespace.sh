#!/bin/bash
create_namespace(){
  local cluster_namespace=$1
    #create namespace
  if kubectl get namespaces | grep "$cluster_namespace" ; then
    echo "Namespace $cluster_namespace already present"
  else
    echo "Creating namespace $cluster_namespace"
    kubectl create namespace "$cluster_namespace"
  fi
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  create_namespace "$@"
fi