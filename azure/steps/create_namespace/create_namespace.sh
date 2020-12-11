#!/bin/bash
create_namespace(){ #public: creates a namespace for kubectl deployment so each test run executes in separate namespace
  local _cluster_namespace=$1
  if kubectl get namespaces | grep "$_cluster_namespace" ; then
    echo "Namespace $_cluster_namespace already present"
  else
    echo "Creating namespace $_cluster_namespace"
    kubectl create namespace "$_cluster_namespace"
  fi
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  create_namespace "$@"
fi