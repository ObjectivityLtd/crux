#!/bin/bash
#help functions

wait_for_pod() {
  local service_replicas="0/1"
  local service_namespace=$1
  local service=$2
  local service_replicas_number=$3
  local sleep_time_s=$4

  status="Terminating"
  printf "\nWait for service $service pods to be in Running status with interval $sleep_interval"
  local elapsed=0
  until [[ "$status" == "Running" ]]; do
    sleep $sleep_time_s
    status=$(kubectl -n $service_namespace get po | grep $service | awk '{print $3}' | sort | uniq) # this will display also old pods until they are gone
    printf "\nService $service pods statuses: $(echo $status | xargs)"
  done

}

wait_for_pods() {
  local service_namespace=$1
  local service_replicas_number=$2
  local sleep_time_s=$3
  shift 3
  IFS=' ' read -r -a services <<<"$@"
  for service in "${services[@]}"; do
    wait_for_pod $service_namespace $service $service_replicas_number $sleep_time_s
  done

}
#display warning message if deployment is not correct e.g. more pods on nodes than allowed
displayDeploymentCorrectnessStatus() {
  local cluster_namespace=$1
  echo ""
  echo "Deployment scheduled on: "
  kubectl -n "$cluster_namespace" get pods -o wide
  kubectl -n "$cluster_namespace" get svc
  local rowsNumber=$(kubectl get -n "$cluster_namespace" pods -o wide | awk {'print $7'} | wc -l)
  local uniqueRowsNumber=$(kubectl get -n "$cluster_namespace" pods -o wide | awk {'print $7'} | sort | uniq | wc -l)
  #more pods scheduled than nodes in cluster
  if [ "$rowsNumber" -gt "$uniqueRowsNumber" ]; then
    echo "##[warning] There are more jmeter pods scheduled than nodes. You should not do that! Read why https://github.com/ObjectivityLtd/crux/wiki/FAQ"
    echo "##vso[task.complete result=SucceededWithIssues;]DONE"
  fi
}


#a bit too many steps but can support both ARM and k8 only
deploy_to_cluster() {
  local rootPath="$1"/kubernetes/config/deployments
  local cluster_namespace=$2
  local service_master=$3
  local service_slave=$4
  local scale_up_replicas=$5
  local _crux_scale_up_replicas_master=1
  local scale_down_replicas=0
  local sleep_interval=15
  local jmeter_master_deploy_file=$6
  local jmeter_slaves_deploy_file=$7
  local aks_pool=$8

  if [ -z "$aks_pool" ]; then
    :
  else
    sed -i "s/{{agentpool}}/$aks_pool/g" "$rootPath"/*.yaml
  fi
  echo "Using deployment rules. $jmeter_master_deploy_file and $jmeter_slaves_deploy_file"

  local jmeter_master_configmap_file="jmeter_master_configmap.yaml"
  local jmeter_shared_volume_file="jmeter_shared_volume.yaml"
  local jmeter_shared_volume_sc_file="jmeter_shared_volume_sc.yaml"
  local jmeter_slaves_svc_file="jmeter_slaves_svc.yaml"

  #re-deploy per defaults
  if kubectl get deployments -n "$cluster_namespace" | grep "$service_master"; then
    echo "Deployments are already present. Skipping new deploy. Use attach.to.existing.kubernetes.yaml if you want to redeploy"
  else
    if kubectl get sc -n "$cluster_namespace" | grep jmeter-shared-disk-sc; then
      echo "Storage class already present. Skipping creation."
    else
      echo "Create storage class."
      kubectl create -n "$cluster_namespace" -f "$rootPath/$jmeter_shared_volume_sc_file"
    fi
    kubectl create -n "$cluster_namespace" -f "$rootPath/$jmeter_shared_volume_file"
    kubectl create -n "$cluster_namespace" -f "$rootPath/$jmeter_slaves_deploy_file"
    kubectl create -n "$cluster_namespace" -f "$rootPath/$jmeter_slaves_svc_file"
    kubectl create -n "$cluster_namespace" -f "$rootPath/$jmeter_master_configmap_file"
    kubectl create -n "$cluster_namespace" -f "$rootPath/$jmeter_master_deploy_file"
  fi

  echo "Rescaling down and up to assure clean test env. Scaling to 0 first. "
  kubectl scale -n "$cluster_namespace" --replicas="$scale_down_replicas" -f "$rootPath/$jmeter_master_deploy_file"
  kubectl scale -n "$cluster_namespace" --replicas="$scale_down_replicas" -f "$rootPath/$jmeter_slaves_deploy_file"

  echo "Scale up master to $_crux_scale_up_replicas_master and slaves to $scale_up_replicas"
  kubectl scale -n "$cluster_namespace" --replicas="$_crux_scale_up_replicas_master" -f "$rootPath/$jmeter_master_deploy_file"
  kubectl scale -n "$cluster_namespace" --replicas="$scale_up_replicas" -f "$rootPath/$jmeter_slaves_deploy_file"

  wait_for_pods "$cluster_namespace" $_crux_scale_up_replicas_master $sleep_interval $service_master
  wait_for_pods "$cluster_namespace" $scale_up_replicas $sleep_interval $service_slave
  displayDeploymentCorrectnessStatus "$cluster_namespace"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  deploy_to_cluster "$@"
fi
