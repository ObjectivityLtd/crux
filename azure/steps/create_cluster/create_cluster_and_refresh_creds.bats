#!/usr/bin/env bash
# if you execute these tests on Windows git bash, make sure you install jq via choco: chocolatey install jq

load $HOME/test/test_helper/bats-assert/load.bash
load $HOME/test/test_helper/bats-support/load.bash

function setup(){
  source "$BATS_TEST_DIRNAME/create_cluster_and_refresh_creds.sh"
  create_cluster(){
    echo "Called $FUNCNAME"
  }
  _refresh_creds(){
    echo "Called $FUNCNAME"
  }
  source(){
    :
  }
  export -f _refresh_creds create_cluster source
}
function teardown(){
  unset source
}

@test "UT:create_cluster_and_refresh_creds: should call create_cluster and _refresh_creds" {
  run create_cluster_and_refresh_creds 1 2 3 4 5 6 7 8
  assert_output --partial "Called create_cluster"
  assert_output --partial "Called _refresh_creds"
}
