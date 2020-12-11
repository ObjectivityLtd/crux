_display_cluster_pools() {
  local _cluster_name=$1
  local _resource_group=$2
  local _message=$3
  echo "$_message"
  az aks nodepool list -g "$_resource_group" --cluster-name "$_cluster_name" --output table
}

_display_crux_pools_number() { #public: displays current crux pools on cluster based on crux label
  local _cluster_name=$1
  local _resource_group=$2
  local _crux_label=$3

  echo "##[info] Searching for crux pools on cluster $_cluster_name"
  local _active_crux_pools=$(az aks nodepool list -g "$_resource_group" --cluster-name "$_cluster_name" -o json --query [?nodeLabels].{n:nodeLabels} | grep "$_crux_label" | wc -l)
  echo "Currently active crux pools number: $_active_crux_pools"
}
_confirm_pool_created() { #public: verifies pool has been created
  local _cluster_name=$1
  local _resource_group=$2
  local _nodepool_name=$3
  if az aks nodepool list -g "$_resource_group" --cluster-name "$_cluster_name" --output table | grep "$_nodepool_name"; then
    echo "##[info] Pool has been created successfully."
  else
    echo "##[error] Pool has not been successfully created. Lacking capacity?"
    echo "##vso[task.complete result=Failed;]DONE"
  fi
}
create_nodepool() { #public: creates a nodepool for test run inside specified cluster, size equal to # slaves replicase + 1 master for 1-1 pod/node distribution
  local _nodepool_name=$1
  local _cluster_name=$2
  local _crux_label=$3
  local _crux_label_value=$4
  local _resource_group=$5
  local _scale_up_replicas=$6
  local _node_count=$(($_scale_up_replicas + 1)) # + 1 for the master
  local _node_size=$7

  _display_crux_pools_number "$_cluster_name" "$_resource_group" "$_crux_label"
  echo "Creating dedicated pool on $_cluster_name - $_nodepool_name with $_node_count nodes sized as $_node_size"
  echo "##[command]az aks nodepool add --resource-group $_resource_group --cluster-name $_cluster_name  --name $_nodepool_name --node-count $_node_count --node-vm-size $_node_size --labels $_crux_label=$_crux_label_value -o table"
  az aks nodepool add \
  --resource-group "$_resource_group" \
  --cluster-name "$_cluster_name" \
  --name "$_nodepool_name" \
  --node-count "$_node_count" \
  --node-vm-size "$_node_size" \
  --labels "$_crux_label"="$_crux_label_value" \
  --output table

  _display_cluster_pools "$_cluster_name" "$_resource_group" "Available pools on this cluster: "
  echo "This build will use the following nodepool to run performance tests:"
  _confirm_pool_created "$_cluster_name" "$_resource_group" "$_nodepool_name"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  create_nodepool "$@"
fi
