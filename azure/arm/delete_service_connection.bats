#!/usr/bin/env bash
# if you execute these tests on Windows git bash, make sure you install jq via choco: chocolatey install jq

load $HOME/test/test_helper/bats-assert/load.bash
load $HOME/test/test_helper/bats-support/load.bash

function setup(){
  source delete_service_connection.sh
}


@test "UT:delete_service_connection: When service_connection_id is empty function skips" {
  curl(){
    echo""
  }
  export -f curl
  run delete_service_connection
  assert_output --partial "skipping connection deletion"
  unset curl
}