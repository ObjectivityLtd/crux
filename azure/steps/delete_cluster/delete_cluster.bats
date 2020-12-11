#!/usr/bin/env bash
# if you execute these tests on Windows git bash, make sure you install jq via choco: chocolatey install jq

load $HOME/test/test_helper/bats-assert/load.bash
load $HOME/test/test_helper/bats-support/load.bash
load $HOME/test/'test_helper/bats-support/load.bash'

setup(){
  source "$BATS_TEST_DIRNAME/delete_cluster.sh"
  az(){
    echo "$*"
  }
  export -f az
  run delete_cluster "cluster_name" "resource_group"
}
teradown(){
  unset az
}
@test "UT:delete_cluster: should print confirm message" {
  assert_success
  assert_output --partial "Cluster cluster_name:resource_group has been scheduled for deletion."
}
@test "UT:delete_cluster: deletion should be asynchronous and without confirmation" {
  assert_output --partial "aks delete --name cluster_name --resource-group resource_group --yes --no-wait"
}