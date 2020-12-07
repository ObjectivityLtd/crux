#!/usr/bin/env bash
# if you execute these tests on Windows git bash, make sure you install jq via choco: chocolatey install jq

load $HOME/test/test_helper/bats-assert/load.bash
load $HOME/test/test_helper/bats-support/load.bash

function setup(){
  source delete_cluster_and_connection.sh
}


@test "UT:delete_cluster_and_connection: Deletion should delete cluster and connection" {
  #these are spies
  delete_service_connection(){
    echo "__delete_service_connection"
  }
  delete_cluster(){
    echo "__delete_cluster"
  }
  source(){
    echo "__source"
  }
  export -f delete_service_connection delete_cluster source
  run delete_cluster_and_connection "path" "cluster_name" "resource_group" "org" "project" "user" "pat" "connection_name" "noskip"
  assert_success
  assert_output --partial  "__delete_service_connection"
  assert_output --partial  "__delete_cluster"
  assert_output --partial  "__source"
  unset source
}