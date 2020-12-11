#!/usr/bin/env bash
# if you execute these tests on Windows git bash, make sure you install jq via choco: chocolatey install jq

load $HOME/test/test_helper/bats-assert/load.bash
load $HOME/test/test_helper/bats-support/load.bash

function setup(){
  source "$BATS_TEST_DIRNAME/create_nodepool.sh"
  _display_crux_pools_number(){
    echo "Called function $FUNCNAME"
  }
  _display_cluster_pools (){
     echo "Called function $FUNCNAME"
  }
  _confirm_pool_created(){
   echo "Called function $FUNCNAME"
  }
  az(){
    echo "Called function $FUNCNAME $*"
  }
  export -f az _display_crux_pools_number _display_cluster_pools _confirm_pool_created
  run create_nodepool nodepool_name cluster_name crux_label crux_label_value resource_group 0 node_size
}
function teardown(){
  unset az
}

@test "UT:create_nodepool calls az aks nodepool add with parameters" {
  assert_output --partial "Called function az aks nodepool add --resource-group resource_group --cluster-name cluster_name --name nodepool_name --node-count 1 --node-vm-size node_size --labels crux_label=crux_label_value --output table"
}
@test "UT:create_nodepool calls _display_crux_pools_number" {
  assert_output --partial "Called function _display_crux_pools_number"
}
@test "UT:create_nodepool calls _display_cluster_pools" {
  assert_output --partial "Called function _display_cluster_pools"
}
@test "UT:create_nodepool calls _confirm_pool_created" {
  assert_output --partial "Called function _confirm_pool_created"
}
