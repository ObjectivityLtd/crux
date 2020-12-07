#!/usr/bin/env bash
# if you execute these tests on Windows git bash, make sure you install jq via choco: chocolatey install jq

load $HOME/test/test_helper/bats-assert/load.bash
load $HOME/test/test_helper/bats-support/load.bash

function setup(){
  source delete_nodepool.sh
  az(){
    echo "Called function $FUNCNAME $*"
  }
  export -f az
}
function teardown(){
  unset az
}

@test "UT:delete_nodepool calls az aks nodepool delete with parameters" {
  run delete_nodepool nodepool_name cluster_name resource_group
  assert_output --partial "Called function az aks nodepool delete -g resource_group --cluster-name cluster_name --name nodepool_name --no-wait"
}