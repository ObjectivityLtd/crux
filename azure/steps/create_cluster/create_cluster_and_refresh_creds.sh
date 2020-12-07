#!/bin/bash
display_kubectl_config(){
  kubectl config view
}
refresh_creds(){
  local resource_group=$1
  local cluster_name=$2
  az aks get-credentials --resource-group "$resource_group" --name "$cluster_name" --overwrite-existing
}
create_cluster_and_refresh_creds() {
  local deployment_name=$1
  local resource_group=$2
  local template_file=$3
  local node_size=$4
  local node_count=$5
  local cluster_name_prefix=$6
  local output_variable=$7
  local path=${8}


  source "$path"/create_cluster.sh
  create_cluster "$deployment_name" "$resource_group" "$template_file" "$node_size" "$node_count" "$cluster_name_prefix" "$output_variable"

  refresh_creds "$resource_group" "${!output_variable}"
  display_kubectl_config
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  create_cluster_and_refresh_creds "$@"
fi