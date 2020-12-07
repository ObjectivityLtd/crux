#!/bin/bash
create_cluster() {
  local deployment_name=$1
  local resource_group=$2
  local template_file=$3
  local node_size=$4
  local node_count=$5
  local cluster_name_prefix=$6
  local output_variable=$7

  output=$(az deployment group create --name "$deployment_name" --resource-group "$resource_group" --template-file "$template_file" --parameters location="westeurope" nodeSize="$node_size" nodeCount="$node_count" clusterNamePrefix="$cluster_name_prefix")
  cluster_name=$(echo $output |jq -r '.properties.outputs.name.value')
  echo "Cluster name created: $cluster_name"
  echo "##vso[task.setvariable variable=$output_variable]${cluster_name}" #set in pipeline
  printf -v "$output_variable" "$cluster_name" #set in script, this is required because azure task will not set it for current script only subsequent steps
  echo "OUTPUT VAR: $output_variable"
  echo "OUTPUT VAR EXPANDED ${!output_variable}"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  create_cluster "$@"
fi