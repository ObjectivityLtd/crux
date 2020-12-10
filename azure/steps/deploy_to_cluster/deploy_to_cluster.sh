#!/bin/bash
#help functions

source ../../lib/utils.sh

_wait_for_pod() { #public: wait for pods of a given type to be in Running state
  local _service_replicas="0/1"
  local _service_namespace=$1
  local _service=$2
  local _service_replicas_number=$3
  local _sleep_time_s=$4
  local _status="Terminating"
  printf "\nWait for service %s pods to be in Running status with interval %s" "$_service" "$_sleep_time_s"
  until [[ "$_status" == "Running" ]]; do
    sleep "$_sleep_time_s"
    _status="$( \
      kubectl -n "$_service_namespace" get po \
      | grep "$_service" \
      | awk '{print $3}' \
      | sort \
      | uniq)" # this will display also old pods until they are gone
    printf "\nService %s pods statuses: %s " "$_service" "$(echo "$_status" | xargs)"
  done

}

_wait_for_pods() { #public: waits for pods to be running for a list of services
  local _service_namespace=$1
  local _service_replicas_number=$2
  local _sleep_time_s=$3
  shift 3
  IFS=' ' read -r -a _services <<<"$@"
  for _service in "${_services[@]}"; do
    _wait_for_pod "$_service_namespace" "$_service" "$_service_replicas_number" "$_sleep_time_s"
  done

}
_display_deployment_correctness_status() { #public: #display warning message if deployment is not correct e.g. more pods on nodes than allowed
  local _cluster_namespace=$1
  printf "\nDeployment scheduled on: \n %s \n%s" "$(kubectl -n "$_cluster_namespace" get pods -o wide)" "$(kubectl -n "$_cluster_namespace" get svc)"
  local _pods_nodes="$(kubectl get -n "$_cluster_namespace" pods -o wide | awk '{print $7}')"
  local _pods_deployed_count="$(echo "$_pods_nodes" | wc -l)"
  local _nodes_used_count="$(echo "$_pods_nodes" | sort | uniq | wc -l)"
  #more pods scheduled than nodes in cluster
  echo "$_pods_deployed_count $__nodes_used_count"
  if [ "$_pods_deployed_count" -gt "$_nodes_used_count" ]; then
    log_warn "There are more jmeter pods scheduled than nodes. You should not do that! Read why https://github.com/ObjectivityLtd/crux/wiki/FAQ"
    echo "##vso[task.complete result=SucceededWithIssues;]DONE"
  fi
}


deploy_to_cluster() {
  local _root_path="$1/kubernetes/config/deployments"
  local _cluster_namespace=$2
  local _service_master=$3
  local _service_slave=$4
  local _scale_up_replicas_slave=$5
  local _jmeter_master_deploy_file=$6
  local _jmeter_slaves_deploy_file=$7
  local _aks_pool=$8
  local _sleep_interval=15


  local _scale_up_replicas_master=1
  local _jmeter_master_configmap_file="jmeter_master_configmap.yaml"
  local _jmeter_shared_volume_file="jmeter_shared_volume.yaml"
  local _jmeter_shared_volume_sc_file="jmeter_shared_volume_sc.yaml"
  local _jmeter_slaves_svc_file="jmeter_slaves_svc.yaml"

  if [ -z "$_aks_pool" ]; then
    :
  else
    sed -i "s/{{agentpool}}/$_aks_pool/g" "$_root_path"/*.yaml
  fi
  echo "Using deployment rules. $_jmeter_master_deploy_file and $_jmeter_slaves_deploy_file"



  #re-deploy per defaults
  if kubectl get deployments -n "$_cluster_namespace" | grep "$_service_master"; then
    echo "Deployments are already present. Skipping new deploy."
  else
    if kubectl get sc -n "$_cluster_namespace" | grep jmeter-shared-disk-sc; then
      echo "Storage class already present. Skipping creation."
    else
      echo "Create storage class."
      kubectl create -n "$_cluster_namespace" -f "$_root_path/$_jmeter_shared_volume_sc_file"
    fi
    kubectl create -n "$_cluster_namespace" -f "$_root_path/$_jmeter_shared_volume_file"
    kubectl create -n "$_cluster_namespace" -f "$_root_path/$_jmeter_slaves_deploy_file"
    kubectl create -n "$_cluster_namespace" -f "$_root_path/$_jmeter_slaves_svc_file"
    kubectl create -n "$_cluster_namespace" -f "$_root_path/$_jmeter_master_configmap_file"
    kubectl create -n "$_cluster_namespace" -f "$_root_path/$_jmeter_master_deploy_file"
  fi

  echo "Scale up master to $_scale_up_replicas_master and slaves to $_scale_up_replicas_slave"
  kubectl scale -n "$_cluster_namespace" --replicas="$_scale_up_replicas_master" -f "$_root_path/$_jmeter_master_deploy_file"
  kubectl scale -n "$_cluster_namespace" --replicas="$_scale_up_replicas_slave" -f "$_root_path/$_jmeter_slaves_deploy_file"

  _wait_for_pods "$_cluster_namespace" $_scale_up_replicas_master $_sleep_interval $_service_master
  _wait_for_pods "$_cluster_namespace" $_scale_up_replicas_slave $_sleep_interval $_service_slave
  _display_deployment_correctness_status "$_cluster_namespace"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  deploy_to_cluster "$@"
fi
