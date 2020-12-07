#!/usr/bin/env bash
# if you execute these tests on Windows git bash, make sure you install jq via choco: chocolatey install jq

load $HOME/test/test_helper/bats-assert/load.bash
load $HOME/test/test_helper/bats-support/load.bash

function setup(){
  source "$BATS_TEST_DIRNAME/delete_cluster.sh"
}


@test "UT:delete_cluster: should print confirm message" {
  az(){
    :
  }
  export -f az
  run delete_cluster "cluster_name" "resource_group"
  assert_success
  assert_output "Cluster cluster_name:resource_group has been scheduled for deletion."
  unset az
}

@test "UT:delete_cluster: deletion should be asynchronous and without confirmation" {
  az(){
    :
  }

  run cat "$BATS_TEST_DIRNAME/delete_cluster.sh"
  assert_output --partial "--yes --no-wait"

}