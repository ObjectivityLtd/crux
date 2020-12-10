#!/usr/bin/env bash
# if you execute these tests on Windows git bash, make sure you install jq via choco: chocolatey install jq

load $HOME/test/test_helper/bats-assert/load.bash
load $HOME/test/test_helper/bats-support/load.bash

function setup(){
  source "$BATS_TEST_DIRNAME/deploy_to_cluster.sh"
  cp "$BATS_TEST_DIRNAME/../test_data/jmeter_master_deploy_required.yaml" "$BATS_TMPDIR"
}
function teardown(){
  :
}

@test "UT:replace_aks_pool_name calls proper sed command" {
  sed(){
    echo $*
  }
  export -f sed
  run _replace_aks_pool_name pool path
  assert_output "-i s/{{agentpool}}/pool/g path/*.yaml"
  unset sed
}

@test "IT:replace_aks_pool_name replaces {{agentpool}} in file correctly" {
  run _replace_aks_pool_name test_pool "$BATS_TMPDIR"
  local actual_output=$(cat "$BATS_TMPDIR"/jmeter_master_deploy_required.yaml)
  local expected_output=$(cat "$BATS_TEST_DIRNAME"/test_data/jmeter_master_deploy_required.yaml)
  assert_equal "$actual_output" "$expected_output"
}


@test "UT: deploy_to_cluster calls replace_aks_pool_name if pool name not empty" {
  _replace_aks_pool_name(){
    echo "Called $FUNCNAME"
    exit 1
  }
  kubectl(){
    :
  }
  _wait_for_pods(){
    :
     }
  _display_deployment_correctness_status(){
    :
   }
  export -f _replace_aks_pool_name _wait_for_pods kubectl _display_deployment_correctness_status
  run deploy_to_cluster 1 2 3 4 5 6 7 8 "pool_name"
  assert_output "Called _replace_aks_pool_name"
}