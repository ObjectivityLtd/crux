display_cluster_pools() {
  local cluster_name=$1
  local resource_group=$2
  local message=$3
  echo "$message"
  az aks nodepool list -g "$resource_group" --cluster-name "$cluster_name" --output table
}

display_crux_pools_number() {
  local cluster_name=$1
  local resource_group=$2
  local crux_label=$3

  echo "##[info] Searching for crux pools on cluster $cluster_name"
  active_crux_pools=$(az aks nodepool list -g "$resource_group" --cluster-name "$cluster_name" -o json --query [?nodeLabels].{n:nodeLabels} | grep "$crux_label" | wc -l)
  echo "Currently active crux pools number: $active_crux_pools"
}
confirm_pool_created() {
  local cluster_name=$1
  local resource_group=$2
  local nodepool_name=$3
  if az aks nodepool list -g "$resource_group" --cluster-name "$cluster_name" --output table | grep "$nodepool_name"; then
    echo "##[info] Pool has been created successfully."
  else
    echo "##[error] Pool has not been successfully created. Lacking capacity?"
    echo "##vso[task.complete result=Failed;]DONE"
  fi
}
create_nodepool() {
  local nodepool_name=$1
  local cluster_name=$2
  local crux_label=$3
  local crux_label_value=$4
  local resource_group=$5
  local scale_up_replicas=$6
  local node_count=$(($scale_up_replicas + 1)) # + 1 for the master
  local node_size=$7

  display_crux_pools_number "$cluster_name" "$resource_group" "$crux_label"
  echo "Creating dedicated pool on $cluster_name - $nodepool_name with $node_count nodes sized as $node_size"
  echo "##[command]az aks nodepool add --resource-group $resource_group --cluster-name $cluster_name  --name $nodepool_name --node-count $node_count --node-vm-size $node_size --labels $crux_label=$crux_label_value -o table"
  az aks nodepool add \
  --resource-group "$resource_group" \
  --cluster-name "$cluster_name" \
  --name "$nodepool_name" \
  --node-count "$node_count" \
  --node-vm-size "$node_size" \
  --labels "$crux_label"="$crux_label_value" \
  --output table

  display_cluster_pools "$cluster_name" "$resource_group" "Available pools on this cluster: "
  echo "This build will use the following nodepool to run performance tests:"
  confirm_pool_created "$cluster_name" "$resource_group" "$nodepool_name"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  create_nodepool "$@"
fi
