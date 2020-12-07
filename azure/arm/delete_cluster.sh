#!/bin/bash
delete_cluster() {
  local cluster_name=$1
  local resource_group=$2
  az aks delete --name "$cluster_name" --resource-group "$resource_group" --yes --no-wait
  echo "Cluster $cluster_name:$resource_group has been scheduled for deletion."
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  delete_cluster "$@"
fi