#!/usr/bin/env bash

function _set_variables() { #public: sets shared variables for the script
  working_dir="$(pwd)"
  jmx="$2"
  data_dir="$3"
  data_dir_relative="$4"
  user_args="$5"
  root_dir=$working_dir/../../../
  LOCAL_REPORT_DIR=$working_dir/../../../kubernetes/tmp/report
  LOCAL_SERVER_LOGS_DIR=$working_dir/../../../kubernetes/tmp/server_logs
  report_dir=report
  test_dir=/test
  tmp=/tmp
  report_args="-o $tmp/$report_dir -l $tmp/results.csv -e"
  test_name="$(basename "$root_dir/$jmx")"
  shared_mount="/shared"
}

_prepare_env() { #public: prepares env for execution, sets MASTER_POD
  local _cluster_namespace=$1
  local _local_report_dir=$2
  local _server_logs_dir=$3

  #delete evicted pods first
  kubectl get pods -n "$_cluster_namespace" --field-selector 'status.phase==Failed' -o json | kubectl delete -f -
  MASTER_POD=$(kubectl get po -n "$_cluster_namespace" | grep Running | grep jmeter-master | awk '{print $1}')
  #create necessary dirs
  mkdir -p "$_local_report_dir" "$_server_logs_dir"
}

_get_slave_pods() { #public: sets SLAVE_PODS_ARRAY
  local _cluster_namespace=$1
  local _slave_pods=$(kubectl get po -n "$_cluster_namespace" --field-selector 'status.phase==Running' | grep jmeter-slave | awk '{print $1}' | xargs)
  IFS=' ' read -r -a SLAVE_PODS_ARRAY <<<"$_slave_pods"
}
_get_pods() { #public: sets SLAVE_PODS_ARRAY
  local _cluster_namespace=$1
  local _pods=$(kubectl get po -n "$_cluster_namespace" --field-selector 'status.phase==Running' | grep jmeter- | awk '{print $1}' | xargs)
  IFS=' ' read -r -a PODS_ARRAY <<<"$_pods"
}

_clean_pods() {
  local _cluster_namespace=$1
  local _master_pod=$2
  shift 2
  local _pods_array=("${@}")
  echo "Cleaning on $_master_pod"
  kubectl exec -i -n "$_cluster_namespace" "$_master_pod" -- bash -c "rm -Rf $shared_mount/*"
  for pod in "${_pods_array[@]}"; do
    echo "Cleaning on $pod"
    #we only clean test data, jmeter-server.log needs to stay
    kubectl exec -i -n "$_cluster_namespace" "$pod" -- bash -c "rm -Rf $test_dir/*.csv"
    kubectl exec -i -n "$_cluster_namespace" "$pod" -- bash -c "rm -Rf $test_dir/*.py"
    kubectl exec -i -n "$_cluster_namespace" "$pod" -- bash -c "rm -Rf $test_dir/*.jmx"
  done
}
#this should be sequential copy instead of shared drive because of IO
_download_server_logs() {
  local _cluster_namespace=$1
  local _server_logs_dir=$2
  shift 2
  local _slave_pods_array=("$@")
  echo "Archiving server logs"
  for pod in "${_slave_pods_array[@]}"; do
    echo "Getting jmeter-server.log on $pod"
    kubectl cp "$_cluster_namespace/$pod:/test/jmeter-server.log" "$_server_logs_dir/$pod-jmeter-server.log"
  done
}
_list_pods_contents() {
  local _cluster_namespace=$1
  shift 1
  local _pods_array=("${@}")
  for pod in "${_pods_array[@]}"; do
    echo "$test_dir on $pod"
    kubectl exec -i -n "$_cluster_namespace" $pod -- ls -1 "/$test_dir/" |awk '$0="  --"$0'

    echo "$shared_mount on $pod"
    kubectl exec -i -n "$_cluster_namespace" $pod -- ls -1 "/$shared_mount/" |awk '$0="  --"$0'
  done
}

#sts and csv data should be copied to /shared which is a pvc mount
_copy_data_to_shared_drive() {
    local _cluster_namespace=$1
    local _master_pod=$2
    local _folder_basename=$(echo "${data_dir##*/}")
    echo "Copying contents of repository $_folder_basename directory to pod : $_master_pod"
    kubectl cp "$root_dir/$data_dir" -n "$_cluster_namespace" "$_master_pod:$shared_mount/"
    echo "Unpacking data on pod : $_master_pod to $shared_mount folder"
    kubectl exec -i -n "$_cluster_namespace" "$_master_pod" -- bash -c "cp -r $shared_mount/$_folder_basename/* $shared_mount/" #unpack to /test
}
#jmx files should land on /test at master pod
_copy_jmx_to_master_pod() {
  local _cluster_namespace=$1
  local _master_pod=$2
  kubectl cp "$root_dir/$jmx" -n "$_cluster_namespace" "$_master_pod:/$test_dir/$test_name"
}
#clean previous run thins if necessary
_clean_master_pod() {
  local _cluster_namespace=$1
  local _master_pod=$2
  kubectl exec -i -n "$_cluster_namespace" "$_master_pod" -- rm -Rf "$tmp"
  kubectl exec -i -n "$_cluster_namespace" "$_master_pod" -- mkdir -p "$tmp/$report_dir"
  kubectl exec -i -n "$_cluster_namespace" "$_master_pod" -- touch "$test_dir/errors.xml"
}
#runs actual tests
_run_jmeter_test() {
  local _cluster_namespace=$1
  local _master_pod=$2
  printf "\t\n Jmeter user args $user_args \n"
  kubectl exec -i -n "$_cluster_namespace" "$_master_pod" -- /bin/bash /load_test $test_name " $report_args $user_args "
}
#copy artifacts from master jmeter
_download_test_results() {
  local _cluster_namespace=$1
  local _master_pod=$2
  local _local_report_dir=$3
  kubectl cp "$_cluster_namespace/$_master_pod:$tmp/$report_dir" "$_local_report_dir/"
  kubectl cp "$_cluster_namespace/$_master_pod:$tmp/results.csv" "$working_dir/../../../kubernetes/tmp/results.csv"
  kubectl cp "$_cluster_namespace/$_master_pod:/test/jmeter.log" "$working_dir/../../../kubernetes/tmp/jmeter.log"
  kubectl cp "$_cluster_namespace/$_master_pod:/test/errors.xml" "$working_dir/../../../kubernetes/tmp/errors.xml"
  head -n10 "$working_dir/../../../kubernetes/tmp/results.csv"
}

jmeter() {
  #server logs need to be copied back instead of writing to a shared drive because of IO
  #data for sts should be copied to /test (not shared)
  #data for all e.g. CSV should be copied to /shared
  local _cluster_namespace="$1"
  local _jmeter_scenario="$2"
  local _jmeter_data_dir="$3"
  local _jmeter_data_dir_relative="$4"
  local _jmeter_args="$5"

  _set_variables "$_jmeter_scenario" "$_jmeter_data_dir" "$_jmeter_data_dir_relative" "$_jmeter_args"
  _prepare_env "$_cluster_namespace" "$LOCAL_REPORT_DIR" "$LOCAL_SERVER_LOGS_DIR " #sets MASTER_POD and created dirs
  _get_pods "$_cluster_namespace" #sets PODS_ARRAY
  _get_slave_pods "$_cluster_namespace" #sets SLAVE_PODS_ARRAY

  #verify all is set
  _clean_pods "$_cluster_namespace" "$MASTER_POD" "${PODS_ARRAY[@]}"
  _copy_data_to_shared_drive "$_cluster_namespace" "$MASTER_POD"
  _copy_jmx_to_master_pod "$_cluster_namespace" "$MASTER_POD"
  _clean_master_pod "$_cluster_namespace" "$MASTER_POD"
  _list_pods_contents "$_cluster_namespace" "${PODS_ARRAY[@]}"
  _run_jmeter_test "$_cluster_namespace" "$MASTER_POD"
  _download_test_results "$_cluster_namespace" "$MASTER_POD" "$LOCAL_REPORT_DIR"
  _download_server_logs "$_cluster_namespace" "$LOCAL_SERVER_LOGS_DIR" "${SLAVE_PODS_ARRAY[@]}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  jmeter "$@"
fi