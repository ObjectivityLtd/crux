#!/bin/bash
delete_cluster() { #public: deletes cluster used for running tests
  local _cluster_name=$1
  local _resource_group=$2
  az aks delete --name "$_cluster_name" --resource-group "$_resource_group" --yes --no-wait
  echo "Cluster $_cluster_name:$_resource_group has been scheduled for deletion."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  delete_cluster "$@"
fi