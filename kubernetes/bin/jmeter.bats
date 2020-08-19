#!/usr/bin/env bash

load $HOME/test/test_helper/bats-assert/load.bash
load $HOME/test/test_helper/bats-support/load.bash

setup(){
  source jmeter.sh
  test_tmp_dir=$(mktemp -d -t crux-XXXXXXXXXX)
}
setFakeVARS(){
  tenant=tenant
  data_dir=data_dir
  root_dir=root_dir
  test_dir=test_dir
  test_name=test_name
  report_args=report_args
  user_args=user_args
  master_pod=master_pod
  report_dir=report_dir
  local_report_dir=local_report_dir
  working_dir=working_dir
}

@test "UT: copyTestResultsToLocal copies report, results.csv, errors.xml and jmeter.log from master pod to local drive" {
  kubectl(){
    echo "$@"
  }
  head(){
    :
  }
  export -f kubectl head
  setFakeVARS
  run copyTestResultsToLocal
  assert_output --partial "cp tenant/master_pod:/report_dir local_report_dir/"
  assert_output --partial "cp tenant/master_pod:/results.csv working_dir/../tmp/results.csv"
  assert_output --partial "tenant/master_pod:/test/jmeter.log working_dir/../tmp/jmeter.log"
  assert_output --partial "tenant/master_pod:/test/errors.xml working_dir/../tmp/errors.xml"
  unset head
}


@test "UT: runTest executes remote /load_test script with params" {
  kubectl(){
    echo "$@"
  }
  export -f kubectl
  setFakeVARS
  run runTest
  assert_output --partial "exec -i -n tenant master_pod -- /bin/bash /load_test test_name  report_args user_args"
}

@test "UT: copyDataToPods copies data to all pods " {
  kubectl(){
    echo "$@"
  }
  export -f kubectl
  # shellcheck disable=SC2030
  pods_array=(slave1 master)
  setFakeVARS
  run copyDataToPods
  assert_output --partial "cp root_dir/data_dir -n tenant slave1:test_dir/"
  assert_output --partial "cp root_dir/data_dir -n tenant master:test_dir/"
}

@test "UT: getServerLogs archives all logs from slaves" {
  kubectl(){
    echo "$@"
  }
  export -f kubectl
  slave_pods_array=(slave1 slave2)
  run getServerLogs
  assert_output --partial "cp /slave2:/test/jmeter-server.log /slave2-jmeter-server.log"
  assert_output --partial "cp /slave1:/test/jmeter-server.log /slave1-jmeter-server.log"

}

@test "UT: getSlavePods returns slaves list" {
  kubectl(){
    cat test_data/kubectl_get_pods.txt
  }
  export -f kubectl
  getSlavePods
  [ "jmeter-slaves-6495546c95-fzdn5 jmeter-slaves-6495546c95-vcsjg" == "${slave_pods_array[*]}" ]
}

@test "UT: getPods returns all pods list" {
  kubectl(){
    cat test_data/kubectl_get_pods.txt
  }
  export -f kubectl
  getPods
  [ "jmeter-master-84cdf76f56-fbgtx jmeter-slaves-6495546c95-fzdn5 jmeter-slaves-6495546c95-vcsjg" == "${pods_array[*]}" ]
}

@test "UT: prepareEnv deletes evicted pods" {
  kubectl(){
    echo "$@"
  }
  mkdir(){
    :
  }
  export -f kubectl mkdir
  run prepareEnv
  assert_output "delete -f -"
  unset mkdir
}

@test "UT: setVARS sets all variables" {
  pwd(){
    echo "$test_tmp_dir"
  }
  export -f pwd
  setVARS 1 2 3 4 args
  [ -n "$tenant" ] # not empty
  [ -n "$jmx" ]
  [ -n "$data_dir" ]
  [ -n "$data_dir_relative" ]
  [ -n "$user_args" ]
  [ -n "$root_dir" ]
  [ -n "$local_report_dir" ]
  [ -n "$server_logs_dir" ]
  [ -n "$report_dir" ]
  [ -n "$tmp" ]
  [ -n "$report_args" ]
  [ -n "$test_name" ]

  unset pwd
}

@test "UT: cleanPods removes csv, py and jmx files" {
  kubectl(){
    echo "$@"
  }
  export -f kubectl
  pods_array=(slave1)
  run cleanPods
  assert_output --partial "exec -i -n slave1 -- bash -c rm -Rf /*.csv"
  assert_output --partial "exec -i -n slave1 -- bash -c rm -Rf /*.py"
  assert_output --partial "exec -i -n slave1 -- bash -c rm -Rf /*.jmx"
}

@test "UT: cleanPods does not remove .log files" {
  kubectl(){
    echo "$@"
  }
  export -f kubectl
  pods_array=(slave1)
  run cleanPods
  refute_output --partial "exec -i -n slave1 -- bash -c rm -Rf /*.log"
}

@test "UT: run_main calls all composing functions" {
  setVARS(){ echo "__mock"; }
  prepareEnv() { echo "__mock"; }
  getPods() { echo "__mock"; }
  getSlavePods() { echo "__mock"; }
  cleanPods(){ echo "__mock"; }
  copyDataToPods(){ echo "__mock"; }
  copyTestFilesToMasterPod(){ echo "__mock"; }
  cleanMasterPod(){ echo "__mock"; }
  lsPods(){ echo "__mock"; }
  runTest(){ echo "__mock"; }
  copyTestResultsToLocal(){ echo "__mock"; }
  getServerLogs(){ echo "__mock";}
  export -f setVARS prepareEnv getPods getSlavePods cleanPods copyDataToPods copyTestFilesToMasterPod cleanMasterPod lsPods runTest copyTestResultsToLocal getServerLogs
  run run_main
  CALL_NUMBER=12
  [ "$(echo "$output" | grep "__mock" | wc -l)" -eq $CALL_NUMBER ]
}