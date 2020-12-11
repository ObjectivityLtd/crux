#!/bin/bash
refresh_creds(){ #public: refreshes credentials for kubectl command
  local _resource_group=$1
  local _cluster_name=$2
  az aks get-credentials --resource-group "$_resource_group" --name "$_cluster_name" --overwrite-existing
}
create_cluster_and_refresh_creds() { #public: created cluster and refreshes variables so kubectl can use the context
  local _deployment_name=$1
  local _resource_group=$2
  local _template_file=$3
  local _node_size=$4
  local _node_count=$5
  local _cluster_name_prefix=$6
  local _output_variable_for_cluster_name=$7
  local path=$8

  source "$path"/create_cluster.sh
  create_cluster "$_deployment_name" "$_resource_group" "$_template_file" "$_node_size" "$_node_count" "$_cluster_name_prefix" "$_output_variable_for_cluster_name"
  refresh_creds "$_resource_group" "${!_output_variable_for_cluster_name}"

}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  create_cluster_and_refresh_creds "$@"
fi