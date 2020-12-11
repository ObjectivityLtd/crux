#!/bin/bash
create_cluster() { #public: creates a cluster with dynamically assigned name and sets an AZURE variable holding its name
  local _deployment_name=$1
  local _resource_group=$2
  local _template_file=$3
  local _node_size=$4
  local _node_count=$5
  local _cluster_name_prefix=$6
  local _output_variable_for_cluster_name=$7

  output=$( \
    az deployment group create \
     --name "$_deployment_name" \
     --resource-group "$_resource_group" \
     --template-file "$_template_file" \
     --parameters \
          location="westeurope" \
          nodeSize="$_node_size" \
          nodeCount="$_node_count" \
          clusterNamePrefix="$_cluster_name_prefix" \
          )

  local _cluster_name=$(echo "$output" |jq -r '.properties.outputs.name.value')
  echo "Cluster name created: $_cluster_name"
  echo "##vso[task.setvariable variable=$_output_variable_for_cluster_name]${_cluster_name}" #set in pipeline for subsequent steps
  printf -v "$_output_variable_for_cluster_name" "$_cluster_name" #set in script, this is required because azure task will not set it for current script only subsequent steps
  echo "Cluster names is saved to the following variable: $_output_variable_for_cluster_name"
  echo ", value: ${!_output_variable_for_cluster_name}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  create_cluster "$@"
fi