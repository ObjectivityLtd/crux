#!/usr/bin/env bash
# if you execute these tests on Windows git bash, make sure you install jq via choco: chocolatey install jq

load $HOME/test/test_helper/bats-assert/load.bash
load $HOME/test/test_helper/bats-support/load.bash

function setup(){
  source create_service_connection.sh
}


@test "UT:create_service_connection: All variables are replaced in JSON template" {
  az(){
    echo "http://dummy.url"
  }
  curl(){
    echo "200"
  }
  export -f az
  run create_service_connection "org" "project" "user" "pat" "name" "cluster_name" "resource_group" "."
  assert_success
  run cat payload.json
  refute_output --partial "$"
  unset az curl
}