#!/usr/bin/env bash
#Script created to launch Jmeter tests directly from the current terminal without accessing the jmeter master pod.
#It requires that you supply the path to the jmx file
#After execution, test script jmx file may be deleted from the pod itself but not locally.

function _set_variables() {
  working_dir="$(pwd)"
  #Get namesapce variable
  tenant="$1"
  jmx="$2"
  data_dir="$3"
  data_dir_relative="$4"
  user_args="$5"
  root_dir=$working_dir/../../../
  local_report_dir=$working_dir/../../../kubernetes/tmp/report
  server_logs_dir=$working_dir/../../../kubernetes/tmp/server_logs
  report_dir=report
  test_dir=/test
  tmp=/tmp
  report_args="-o $tmp/$report_dir -l $tmp/results.csv -e"
  test_name="$(basename "$root_dir/$jmx")"
  shared_mount="/shared"
}

_prepare_env() {
  local _cluster_namespace=$1
  #delete evicted pods first
  kubectl get pods -n "$_cluster_namespace" --field-selector 'status.phase==Failed' -o json | kubectl delete -f -
  master_pod=$(kubectl get po -n "$_cluster_namespace" | grep Running | grep jmeter-master | awk '{print $1}')
  #create necessary dirs
  mkdir -p "$local_report_dir" "$server_logs_dir"
}

_get_slave_pods() {
  local _cluster_namespace=$1
  slave_pods=$(kubectl get po -n "$_cluster_namespace" --field-selector 'status.phase==Running' | grep jmeter-slave | awk '{print $1}' | xargs)
  IFS=' ' read -r -a slave_pods_array <<<"$slave_pods"
}
_get_pods() {
  local _cluster_namespace=$1
  pods=$(kubectl get po -n $tenant --field-selector 'status.phase==Running' | grep jmeter- | awk '{print $1}' | xargs)
  IFS=' ' read -r -a pods_array <<<"$pods"
}
_clean_pods() {
  local _cluster_namespace=$1
  echo "Cleaning on $master_pod"
  kubectl exec -i -n "$_cluster_namespace" $master_pod -- bash -c "rm -Rf $shared_mount/*"
  for pod in "${pods_array[@]}"; do
    echo "Cleaning on $pod"
    #we only clean test data, jmeter-server.log needs to stay
    kubectl exec -i -n "$_cluster_namespace" $pod -- bash -c "rm -Rf $test_dir/*.csv"
    kubectl exec -i -n "$_cluster_namespace" $pod -- bash -c "rm -Rf $test_dir/*.py"
    kubectl exec -i -n "$_cluster_namespace" $pod -- bash -c "rm -Rf $test_dir/*.jmx"
  done
}
#this should be sequential copy instead of shared drive because of IO
getServerLogs() {
  echo "Archiving server logs"
  for pod in "${slave_pods_array[@]}"; do
    echo "Getting jmeter-server.log on $pod"
    kubectl cp "$tenant/$pod:/test/jmeter-server.log" "$server_logs_dir/$pod-jmeter-server.log"
  done
}
lsPods() {
  for pod in "${pods_array[@]}"; do
    echo "$test_dir on $pod"
    kubectl exec -i -n $tenant $pod -- ls -1 "/$test_dir/" |awk '$0="  --"$0'

    echo "$shared_mount on $pod"
    kubectl exec -i -n $tenant $pod -- ls -1 "/$shared_mount/" |awk '$0="  --"$0'
  done
}

#sts and csv data should be copied to /shared which is a pvc mount
copyDataToPodsShared() {
    folder_basename=$(echo "${data_dir##*/}")
    echo "Copying contents of repository $folder_basename directory to pod : $master_pod"
    kubectl cp "$root_dir/$data_dir" -n $tenant "$master_pod:$shared_mount/"
    echo "Unpacking data on pod : $master_pod to $shared_mount folder"
    kubectl exec -i -n $tenant $master_pod -- bash -c "cp -r $shared_mount/$folder_basename/* $shared_mount/" #unpack to /test
}
#jmx files should land on /test at master pod
copyTestFilesToMasterPod() {
  kubectl cp "$root_dir/$jmx" -n $tenant "$master_pod:/$test_dir/$test_name"
}
#clean previous run thins if necessary
cleanMasterPod() {
  kubectl exec -i -n $tenant $master_pod -- rm -Rf "$tmp"
  kubectl exec -i -n $tenant $master_pod -- mkdir -p "$tmp/$report_dir"
  kubectl exec -i -n $tenant $master_pod -- touch "$test_dir/errors.xml"
}
#runs actual tests
runTest() {
  printf "\t\n Jmeter user args $user_args \n"
  kubectl exec -i -n $tenant $master_pod -- /bin/bash /load_test $test_name " $report_args $user_args "
}
#copy artifacts from master jmeter
copyTestResultsToLocal() {
  kubectl cp "$tenant/$master_pod:$tmp/$report_dir" "$local_report_dir/"
  kubectl cp "$tenant/$master_pod:$tmp/results.csv" "$working_dir/../tmp/results.csv"
  kubectl cp "$tenant/$master_pod:/test/jmeter.log" "$working_dir/../tmp/jmeter.log"
  kubectl cp "$tenant/$master_pod:/test/errors.xml" "$working_dir/../tmp/errors.xml"
  head -n10 "$working_dir/../tmp/results.csv"
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
  _set_variables "$_cluster_namespace" "$_jmeter_scenario" "$_jmeter_data_dir" "$_jmeter_data_dir_relative" "$_jmeter_args"
  _prepare_env "$_cluster_namespace"
  _get_pods "$_cluster_namespace"
  _get_slave_pods "$_cluster_namespace"
  _clean_pods "$_cluster_namespace"
  copyDataToPodsShared
  copyTestFilesToMasterPod
  cleanMasterPod
  lsPods
  runTest
  copyTestResultsToLocal
  getServerLogs
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  jmeter "$@"
fi