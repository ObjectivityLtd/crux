#!/usr/bin/env bash
# if you execute these tests on Windows git bash, make sure you install jq via choco: chocolatey install jq

load $HOME/test/test_helper/bats-assert/load.bash
load $HOME/test/test_helper/bats-support/load.bash

function setup(){
  source create_nodepool.sh
  display_crux_pools_number(){
    echo "Called function $FUNCNAME"
  }
  display_cluster_pools (){
     echo "Called function $FUNCNAME"
  }
  confirm_pool_created(){
   echo "Called function $FUNCNAME"
  }
  az(){
    echo "Called function $FUNCNAME $*"
  }
  export -f az display_crux_pools_number display_cluster_pools confirm_pool_created
  run create_nodepool nodepool_name cluster_name crux_label crux_label_value resource_group 0 node_size
}
function teardown(){
  unset az
}

@test "UT:create_nodepool calls az aks nodepool add with parameters" {
  assert_output --partial "Called function az aks nodepool add --resource-group resource_group --cluster-name cluster_name --name nodepool_name --node-count 1 --node-vm-size node_size --labels crux_label=crux_label_value --output table"
}
@test "UT:create_nodepool calls display_crux_pools_number" {
  assert_output --partial "Called function display_crux_pools_number"
}
@test "UT:create_nodepool calls display_cluster_pools" {
  assert_output --partial "Called function display_cluster_pools"
}
@test "UT:create_nodepool calls confirm_pool_created" {
  assert_output --partial "Called function confirm_pool_created"
}
