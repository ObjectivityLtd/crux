#!/usr/bin/env bash

_prepare_env() { #public: prepares env for execution, sets MASTER_POD
  local _cluster_namespace=$1
  local _local_report_dir=$2
  local _server_logs_dir=$3
  kubectl get pods -n "$_cluster_namespace" --field-selector 'status.phase==Failed' -o json | kubectl delete -f - #delete evicted pods
  MASTER_POD=$(kubectl get po -n "$_cluster_namespace" | grep Running | grep jmeter-master | awk '{print $1}')    #set master pod globally
  mkdir -p "$_local_report_dir" "$_server_logs_dir"                                                               #creates dirs
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
    kubectl exec -i -n "$_cluster_namespace" "$_pod" -- ls -1 "/$_test_dir/" | awk '$0="  --"$0'
    echo "$_shared_mount on $_pod"
    kubectl exec -i -n "$_cluster_namespace" "$_pod" -- ls -1 "/$_shared_mount/" | awk '$0="  --"$0'
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
  local _local_jmx_path=$3/$4
  local _remote_jmx_path=$5/$6

  kubectl cp "$_local_jmx" -n "$_cluster_namespace" "$_master_pod:/$_remote_jmx_path"
}

_clean_master_pod() { #public: resets folders used in tests
  local _cluster_namespace=$1
  local _master_pod=$2
  local _tmp=$3
  local _report_dir=$4
  local _error_file=$5

  kubectl exec -i -n "$_cluster_namespace" "$_master_pod" -- rm -Rf "$_tmp"
  kubectl exec -i -n "$_cluster_namespace" "$_master_pod" -- mkdir -p "$_report_dir"
  kubectl exec -i -n "$_cluster_namespace" "$_master_pod" -- touch "$_error_file"
}

_run_jmeter_test() { #public: runs actual test from within master pod of a deployment
  local _cluster_namespace=$1
  local _master_pod=$2
  local _test_name=$3
  local _report_args=$4
  local _user_args=$5
  printf "\t\n Jmeter user args $_user_args \n"
  kubectl exec -i -n "$_cluster_namespace" "$_master_pod" -- /bin/bash /load_test "$_test_name" " $_report_args $_user_args "
}

_download_test_results() { #public: downloads test artifacts from master to local storage so we can expose them as pipeline artifacts
  local _cluster_namespace=$1
  local _master_pod=$2
  local _report_dir=$3
  local _results_file=$4
  local _jmeter_log_file=$5
  local _jmeter_error_file=$6
  local _root_dir=$7
  kubectl cp "$_cluster_namespace/$_master_pod:$_report_dir" "$_root_dir/kubernetes/tmp/report/"
  kubectl cp "$_cluster_namespace/$_master_pod:$_results_file" "$_root_dir/kubernetes/tmp/results.csv"
  kubectl cp "$_cluster_namespace/$_master_pod:$_jmeter_log_file" "$_root_dir/kubernetes/tmp/jmeter.log"
  kubectl cp "$_cluster_namespace/$_master_pod:$_jmeter_error_file" "$_root_dir/kubernetes/tmp/errors.xml"
}
_download_server_logs() { #public: downloads jmeter servers logs to local storage so we can archive them as pipeline artifacts
  local _cluster_namespace=$1
  local _server_logs_dir=$2
  local _test_dir=$3
  shift 3
  local _slave_pods_array=("$@")
  local _server_log_file="jmeter-server.log"
  for _pod in "${_slave_pods_array[@]}"; do
    echo "Downloading $_server_log_file from $_pod"
    kubectl cp "$_cluster_namespace/$_pod:/$_test_dir/$_server_log_file" "$_server_logs_dir/$_pod-$_server_log_file"
  done
}

#server logs need to be copied back instead of writing to a shared drive because of IO
#data for sts should be copied to /test (not shared)
#data for all e.g. CSV should be copied to /shared
jmeter() {

  local _root_dir="$1"
  local _cluster_namespace="$2"
  local _jmeter_scenario="$3"
  local _jmeter_data_dir="$4"
  local _jmeter_args="$5"
  local _local_report_dir="$6"
  local _local_server_logs_dir="$7"

  REMOTE_REPORT_DIR=report
  REMOTE_TEST_DIR=/test
  REMOTE_TMP=/tmp
  TEST_NAME="$(basename "$_root_dir/$_jmeter_scenario")"
  REMOTE_SHARED_MOUNT="/shared"
  REMOTE_ERROR_FILE="errors.xml"
  REMOTE_RESULTS_FILE="results.csv"
  REPORT_ARGS="-o $REMOTE_TMP/$REMOTE_REPORT_DIR -l $REMOTE_TMP/$REMOTE_RESULTS_FILE -e"

  _prepare_env "$_cluster_namespace" "$_local_report_dir" "$_local_server_logs_dir"                                               #sets MASTER_POD and created dirs
  _get_pods "$_cluster_namespace"                                                                                                  #sets PODS_ARRAY
  _get_slave_pods "$_cluster_namespace"                                                                                            #sets SLAVE_PODS_ARRAY
  #test flow
  _clean_pods "$_cluster_namespace" "$MASTER_POD" "$REMOTE_TEST_DIR" "$REMOTE_SHARED_MOUNT" "${PODS_ARRAY[@]}"
  _copy_data_to_shared_drive "$_cluster_namespace" "$MASTER_POD" "$_root_dir" "$REMOTE_SHARED_MOUNT" "$_jmeter_data_dir"
  _copy_jmx_to_master_pod "$_cluster_namespace" "$MASTER_POD" "$_root_dir" "$_jmeter_scenario" "$REMOTE_TEST_DIR" "$TEST_NAME"
  _clean_master_pod "$_cluster_namespace" "$MASTER_POD" "$REMOTE_TMP" "$REMOTE_TMP/$REMOTE_REPORT_DIR" "$REMOTE_TEST_DIR/$REMOTE_ERROR_FILE"
  _list_pods_contents "$_cluster_namespace" "$REMOTE_TEST_DIR" "$REMOTE_SHARED_MOUNT" "${PODS_ARRAY[@]}"
  _run_jmeter_test "$_cluster_namespace" "$MASTER_POD" "$TEST_NAME" "$REPORT_ARGS" "$_jmeter_args"
  _download_test_results "$_cluster_namespace" "$MASTER_POD" "$REMOTE_TMP/$REMOTE_REPORT_DIR" "$REMOTE_TMP/$REMOTE_RESULTS_FILE" "/test/jmeter.log" "/test/errors.xml" "$_root_dir"
  _download_server_logs "$_cluster_namespace" "$_local_server_logs_dir" "$REMOTE_TEST_DIR" "${SLAVE_PODS_ARRAY[@]}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  jmeter "$@"
fi
