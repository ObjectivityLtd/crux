#!/usr/bin/env bash
# if you execute these tests on Windows git bash, make sure you install jq via choco: chocolatey install jq

load $HOME/test/test_helper/bats-assert/load.bash
load $HOME/test/test_helper/bats-support/load.bash

function setup(){
  source recreate_service_connection.sh
}


@test "UT:recreate_service_connection: Creation and Deletion should be called" {
  #these are spies
  create_service_connection(){
    echo "__create_service_connection"
  }
  delete_service_connection(){
    echo "__delete_service_connection"
  }
  source(){
    echo "__source"
  }
  export -f create_service_connection delete_service_connection source
  run recreate_service_connection "org" "project" "user" "pat" "name" "cluster_name" "resource_group" "."
  assert_success
  assert_output --partial  "__create_service_connection"
  assert_output --partial  "__delete_service_connection"
  assert_output --partial  "__source"
  unset source
}