#!/usr/bin/env bash

function _set_variables() { #public: sets shared variables for the script
  WORKING_DIR="$(pwd)"
  JMX="$1"
  DATA_DIR="$2"
  data_dir_relative="$3"
  USER_ARGS="$4"
  ROOT_DIR=$WORKING_DIR/../../../
  LOCAL_REPORT_DIR=$WORKING_DIR/../../../kubernetes/tmp/report
  LOCAL_SERVER_LOGS_DIR=$WORKING_DIR/../../../kubernetes/tmp/server_logs
  REPORT_DIR=report
  TEST_DIR=/test
  TMP=/tmp
  REPORT_ARGS="-o $TMP/$REPORT_DIR -l $tmp/results.csv -e"
  TEST_NAME="$(basename "$ROOT_DIR/$JMX")"
  SHARED_MOUNT="/shared"
  ERROR_FILE="errors.xml"
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

_clean_pods() { #public: cleans folders before test
  local _cluster_namespace=$1
  local _master_pod=$2
  local _test_dir=$3
  local _shared_mount=$4
  shift 4
  local _pods_array=("$@")
  echo "Cleaning on $_master_pod"
  kubectl exec -i -n "$_cluster_namespace" "$_master_pod" -- bash -c "rm -Rf $_shared_mount/*"
  for _pod in "${_pods_array[@]}"; do
    echo "Cleaning on $_pod"
    #we only clean test data, jmeter-server.log needs to stay
    kubectl exec -i -n "$_cluster_namespace" "$_pod" -- bash -c "rm -Rf $_test_dir/*.csv"
    kubectl exec -i -n "$_cluster_namespace" "$_pod" -- bash -c "rm -Rf $_test_dir/*.py"
    kubectl exec -i -n "$_cluster_namespace" "$_pod" -- bash -c "rm -Rf $_test_dir/*.jmx"
  done
}
_list_pods_contents() { #public: display conetnts of /shared and /test folder on all k8 pods
  local _cluster_namespace=$1
  local _test_dir=$2
  local _shared_mount=$3
  shift 3
  local _pods_array=("$@")
  for _pod in "${_pods_array[@]}"; do
    echo "$_test_dir on $_pod"
    kubectl exec -i -n "$_cluster_namespace" "$_pod" -- ls -1 "/$_test_dir/" |awk '$0="  --"$0'
    echo "$_shared_mount on $_pod"
    kubectl exec -i -n "$_cluster_namespace" "$_pod" -- ls -1 "/$_shared_mount/" |awk '$0="  --"$0'
  done
}

_copy_data_to_shared_drive() { #public: all test data are copied to /shared which is a pvc mount, STS reads from there too
    local _cluster_namespace=$1
    local _master_pod=$2
    local _root_dir=$3
    local _shared_mount=$4
    local _data_dir=$5
    local _folder_basename=$(echo "${_data_dir##*/}")
    echo "Copying contents of repository $_folder_basename directory to pod : $_master_pod"
    kubectl cp "$_root_dir/$_data_dir" -n "$_cluster_namespace" "$_master_pod:$_shared_mount/"
    echo "Unpacking data on pod : $_master_pod to $_shared_mount folder"
    kubectl exec -i -n "$_cluster_namespace" "$_master_pod" -- bash -c "cp -r $_shared_mount/$_folder_basename/* $_shared_mount/" #unpack to /test
}

_copy_jmx_to_master_pod() { #public: copies .jmx file to test folder /test at master pod
  local _cluster_namespace=$1
  local _master_pod=$2
  local _root_dir=$3
  local _jmx=$4
  local _test_dir=$5
  local _test_name=$6

  kubectl cp "$_root_dir/$_jmx" -n "$_cluster_namespace" "$_master_pod:/$_test_dir/$_test_name"
}

_clean_master_pod() { #public: resets folders used in tests
  local _cluster_namespace=$1
  local _master_pod=$2
  local _test_dir=$3
  local _tmp=$4
  local _report_dir=$5
  local _error_file=$6

  kubectl exec -i -n "$_cluster_namespace" "$_master_pod" -- rm -Rf "$_tmp"
  kubectl exec -i -n "$_cluster_namespace" "$_master_pod" -- mkdir -p "$_tmp/$_report_dir"
  kubectl exec -i -n "$_cluster_namespace" "$_master_pod" -- touch "$_test_dir/$_error_file"
}

 _run_jmeter_test() { #public: runs actual test from within master pod of a deployment
  local _cluster_namespace=$1
  local _master_pod=$2
  local _test_name=$3
  local _report_args=$4
  local _user_args=$5
  printf "\t\n Jmeter user args %s \n" "$__user_args"
  kubectl exec -i -n "$_cluster_namespace" "$_master_pod" -- /bin/bash /load_test "$_test_name" " $_report_args $_user_args "
}
#copy artifacts from master jmeter
_download_test_results() {
  local _cluster_namespace=$1
  local _master_pod=$2
  local _local_report_dir=$3
  local _report_dir=$4
  local _tmp=$5
  local _working_dir=$6
  kubectl cp "$_cluster_namespace/$_master_pod:$_tmp/$_report_dir" "$_local_report_dir/"
  kubectl cp "$_cluster_namespace/$_master_pod:$_tmp/results.csv" "$_working_dir/../../../kubernetes/tmp/results.csv"
  kubectl cp "$_cluster_namespace/$_master_pod:/test/jmeter.log" "$_working_dir/../../../kubernetes/tmp/jmeter.log"
  kubectl cp "$_cluster_namespace/$_master_pod:/test/errors.xml" "$_working_dir/../../../kubernetes/tmp/errors.xml"
  head -n10 "$_working_dir/../../../kubernetes/tmp/results.csv"
}
#this should be sequential copy instead of shared drive because of IO
_download_server_logs() {
  local _cluster_namespace=$1
  local _server_logs_dir=$2
  local _test_dir=$3
  shift 3
  local _slave_pods_array=("$@")
  echo "Archiving server logs"
  for _pod in "${_slave_pods_array[@]}"; do
    echo "Getting jmeter-server.log on $_pod"
    kubectl cp "$_cluster_namespace/$_pod:/$_test_dir/jmeter-server.log" "$_server_logs_dir/$_pod-jmeter-server.log"
  done
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

   #set vars
  _set_variables "$_jmeter_scenario" "$_jmeter_data_dir" "$_jmeter_data_dir_relative" "$_jmeter_args"
  _prepare_env "$_cluster_namespace" "$LOCAL_REPORT_DIR" "$LOCAL_SERVER_LOGS_DIR " #sets MASTER_POD and created dirs
  _get_pods "$_cluster_namespace" #sets PODS_ARRAY
  _get_slave_pods "$_cluster_namespace" #sets SLAVE_PODS_ARRAY

  #test flow
  _clean_pods "$_cluster_namespace" "$MASTER_POD" "$TEST_DIR" "$SHARED_MOUNT" "${PODS_ARRAY[@]}" #OK
  _copy_data_to_shared_drive "$_cluster_namespace" "$MASTER_POD" "$ROOT_DIR" "$SHARED_MOUNT" "$DATA_DIR" #OK
  _copy_jmx_to_master_pod "$_cluster_namespace" "$MASTER_POD" "$ROOT_DIR" "$JMX" "$TEST_DIR" "$TEST_NAME" #OK
  _clean_master_pod "$_cluster_namespace" "$MASTER_POD" "$TEST_DIR" "$TMP" "$REPORT_DIR" "$ERROR_FILE" #OK
  _list_pods_contents "$_cluster_namespace" "$TEST_DIR" "$SHARED_MOUNT" "${PODS_ARRAY[@]}" #OK
  _run_jmeter_test "$_cluster_namespace" "$MASTER_POD" "$TEST_NAME" "$REPORT_ARGS" "$USER_ARGS"
  _download_test_results "$_cluster_namespace" "$MASTER_POD" "$LOCAL_REPORT_DIR" "$REPORT_DIR" "$TMP" "$WORKING_DIR"
  _download_server_logs "$_cluster_namespace" "$LOCAL_SERVER_LOGS_DIR" "$TEST_DIR" "${SLAVE_PODS_ARRAY[@]}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  jmeter "$@"
fi