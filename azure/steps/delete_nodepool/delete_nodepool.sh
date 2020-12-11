delete_nodepool() { #public: deletes nodepool used for test run on the cluster
   local _nodepool_name=$1
   local _cluster_name=$2
   local _resource_group=$3
   echo "##[info] Deleting $__nodepool_name pool on $_cluster_name... "
   echo "##[command] az aks nodepool delete -g "$_resource_group" --cluster-name "$_cluster_name" --name "$_nodepool_name" --no-wait"
   az aks nodepool delete -g "$_resource_group" --cluster-name "$_cluster_name" --name "$_nodepool_name" --no-wait
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  delete_nodepool "$@"
fi