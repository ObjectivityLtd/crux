#!/usr/bin/env bash

load $HOME/test/test_helper/bats-assert/load.bash
load $HOME/test/test_helper/bats-support/load.bash

setup(){
  source "$BATS_TEST_DIRNAME/jmeter.sh"
  test_tmp_dir=$BATS_TMPDIR
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
  shared_mount=shared_mount
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

@test "UT: _copy_data_to_shared_drive copies data to all pods " {
  kubectl(){
    echo "$@"
  }
  export -f kubectl
  # shellcheck disable=SC2030
  setFakeVARS
  run _copy_data_to_shared_drive cluster_namespace master_pod
  assert_output --partial "cp root_dir/data_dir -n cluster_namespace master_pod:shared_mount/"
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

@test "UT: _get_slave_pods returns slaves list" {
  kubectl(){
    cat test_data/kubectl_get_pods.txt
  }
  export -f kubectl
  _get_slave_pods
  [ "jmeter-slaves-6495546c95-fzdn5 jmeter-slaves-6495546c95-vcsjg" == "${slave_pods_array[*]}" ]
}

@test "UT: _get_pods returns all pods list" {
  kubectl(){
    cat test_data/kubectl_get_pods.txt
  }
  export -f kubectl
  _get_pods
  [ "jmeter-master-84cdf76f56-fbgtx jmeter-slaves-6495546c95-fzdn5 jmeter-slaves-6495546c95-vcsjg" == "${pods_array[*]}" ]
}

@test "UT: _prepare_env deletes evicted pods" {
  kubectl(){
    echo "$@"
  }
  mkdir(){
    :
  }
  export -f kubectl mkdir
  run _prepare_env
  assert_output "delete -f -"
  unset mkdir
}

@test "UT: _set_variables sets all variables" {
  pwd(){
    echo "$test_tmp_dir"
  }
  export -f pwd
  _set_variables 1 2 3 4 args
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
  [ -n "$shared_mount" ]

  unset pwd
}

@test "UT: _clean_pods removes csv, py and jmx files" {
  kubectl(){
    echo "$@"
  }
  export -f kubectl
  pods_array=(slave1)
  run _clean_pods cluster_namespace master_pod
  assert_output --partial "exec -i -n cluster_namespace slave1 -- bash -c rm -Rf /*.csv"
  assert_output --partial "exec -i -n cluster_namespace slave1 -- bash -c rm -Rf /*.py"
  assert_output --partial "exec -i -n cluster_namespace slave1 -- bash -c rm -Rf /*.jmx"
}

@test "UT: _clean_pods does not remove .log files" {
  kubectl(){
    echo "$@"
  }
  export -f kubectl
  pods_array=(slave1)
  run _clean_pods cluster_namespace master_pod
  refute_output --partial "exec -i -n cluster_namespace slave1 -- bash -c rm -Rf /*.log"
}

@test "UT: jmeter calls all composing functions" {
  _set_variables(){ echo "__mock"; }
  _prepare_env() { echo "__mock"; }
  _get_pods() { echo "__mock"; }
  _get_slave_pods() { echo "__mock"; }
  _clean_pods(){ echo "__mock"; }
  _copy_data_to_shared_drive(){ echo "__mock"; }
  copyTestFilesToMasterPod(){ echo "__mock"; }
  cleanMasterPod(){ echo "__mock"; }
  lsPods(){ echo "__mock"; }
  runTest(){ echo "__mock"; }
  copyTestResultsToLocal(){ echo "__mock"; }
  getServerLogs(){ echo "__mock";}
  export -f _set_variables _prepare_env _get_pods _get_slave_pods _clean_pods _copy_data_to_shared_drive copyTestFilesToMasterPod cleanMasterPod lsPods runTest copyTestResultsToLocal getServerLogs
  run jmeter
  CALL_NUMBER=12
  [ "$(echo "$output" | grep "__mock" | wc -l)" -eq $CALL_NUMBER ]
}