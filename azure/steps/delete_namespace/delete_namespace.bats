#!/usr/bin/env bash
# if you execute these tests on Windows git bash, make sure you install jq via choco: chocolatey install jq

load $HOME/test/test_helper/bats-assert/load.bash
load $HOME/test/test_helper/bats-support/load.bash

function setup(){
  source "$BATS_TEST_DIRNAME/delete_namespace.sh"
  kubectl (){
    echo "kubectl $*"
  }
  export -f kubectl
}
function teardown(){
  unset kubectl
}

@test "UT:create_namespace: should delete a namespace that is not 'default'" {

  local _namespace=notdefault
  run delete_namespace "$_namespace"
  assert_output --partial "kubectl delete namespace $_namespace"
}

@test "UT:create_namespace: should NOT delete a namespace that is 'default'" {
  kubectl (){
    echo "kubectl $*"
  }
  local _namespace=default
  run delete_namespace "$_namespace"
  refute_output --partial "kubectl delete namespace $_namespace"
}