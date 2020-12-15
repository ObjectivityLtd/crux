#!/usr/bin/env bash

load $HOME/test/test_helper/bats-assert/load.bash
load $HOME/test/test_helper/bats-support/load.bash

setup(){
  source "$BATS_TEST_DIRNAME/jmeter.sh"
  test_tmp_dir=$BATS_TMPDIR
}

@test "UT: _download_test_results copies report, results.csv, errors.xml and jmeter.log from master pod to local drive" {
  kubectl(){
    echo "$@"
  }
  head(){
    :
  }
  export -f kubectl head
  
  run _download_test_results cluster_namespace master_pod /tmp/report_dir /tmp/results.csv /test/jmeter.log /test/errors.xml root_dir/kubernetes/tmp
  assert_output --partial "cp cluster_namespace/master_pod:/tmp/report_dir root_dir/kubernetes/tmp/report"
  assert_output --partial "cp cluster_namespace/master_pod:/tmp/results.csv root_dir/kubernetes/tmp/results.csv"
  assert_output --partial "cluster_namespace/master_pod:/test/jmeter.log root_dir/kubernetes/tmp/jmeter.log"
  assert_output --partial "cluster_namespace/master_pod:/test/errors.xml root_dir/kubernetes/tmp/errors.xml"
  unset head
}


@test "UT: _run_jmeter_test executes remote /load_test script with params" {
  kubectl(){
    echo "$@"
  }
  export -f kubectl
  
  run _run_jmeter_test cluster_namespace master_pod test_name report_args user_args
  assert_output --partial "exec -i -n cluster_namespace master_pod -- /bin/bash /load_test test_name  report_args user_args"
}

@test "UT: _copy_data_to_shared_drive copies data to all pods " {
  kubectl(){
    echo "$@"
  }
  export -f kubectl
  # shellcheck disable=SC2030
  
  run _copy_data_to_shared_drive cluster_namespace master_pod root_dir shared_mount data_dir
  assert_output --partial "cp root_dir/data_dir -n cluster_namespace master_pod:shared_mount/"
}

@test "UT: _download_server_logs archives all logs from slaves" {
  kubectl(){
    echo "$@"
  }
  export -f kubectl
  local _slave_pods_array=(slave1 slave2)
  run _download_server_logs  "$_cluster_namespace" "/foo" "test" "${_slave_pods_array[@]}"
  assert_output --partial "cp /slave2:/test/jmeter-server.log /foo/slave2-jmeter-server.log"
  assert_output --partial "cp /slave1:/test/jmeter-server.log /foo/slave1-jmeter-server.log"

}

@test "UT: _get_slave_pods returns slaves list" {
  kubectl(){
    cat test_data/kubectl_get_pods.txt
  }
  export -f kubectl
  _get_slave_pods
  [ "jmeter-slaves-6495546c95-fzdn5 jmeter-slaves-6495546c95-vcsjg" == "${SLAVE_PODS_ARRAY[*]}" ]
}

@test "UT: _get_pods returns all pods list" {
  kubectl(){
    cat test_data/kubectl_get_pods.txt
  }
  export -f kubectl
  _get_pods
  [ "jmeter-master-84cdf76f56-fbgtx jmeter-slaves-6495546c95-fzdn5 jmeter-slaves-6495546c95-vcsjg" == "${PODS_ARRAY[*]}" ]
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


@test "UT: _clean_pods removes csv, py and jmx files" {
  kubectl(){
    echo "$@"
  }
  export -f kubectl
  pods_array=(slave1)
  run _clean_pods cluster_namespace master_pod test_dir shared_mount "${pods_array[@]}"
  assert_output --partial "exec -i -n cluster_namespace slave1 -- bash -c rm -Rf test_dir/*.csv"
  assert_output --partial "exec -i -n cluster_namespace slave1 -- bash -c rm -Rf test_dir/*.py"
  assert_output --partial "exec -i -n cluster_namespace slave1 -- bash -c rm -Rf test_dir/*.jmx"
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
  _copy_jmx_to_master_pod(){ echo "__mock"; }
  _clean_master_pod(){ echo "__mock"; }
  _list_pods_contents(){ echo "__mock"; }
  _run_jmeter_test(){ echo "__mock"; }
  _download_test_results(){ echo "__mock"; }
  _download_server_logs(){ echo "__mock";}
  export -f _set_variables _prepare_env _get_pods _get_slave_pods _clean_pods _copy_data_to_shared_drive _copy_jmx_to_master_pod _clean_master_pod _list_pods_contents _run_jmeter_test _download_test_results _download_server_logs
  run jmeter
  CALL_NUMBER=11
  [ "$(echo "$output" | grep "__mock" | wc -l)" -eq $CALL_NUMBER ]
}