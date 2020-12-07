#!/usr/bin/env bash
# if you execute these tests on Windows git bash, make sure you install jq via choco: chocolatey install jq

load $HOME/test/test_helper/bats-assert/load.bash
load $HOME/test/test_helper/bats-support/load.bash

function setup(){
  source delete_namespace.sh
}
function teardown(){
  unset kubectl
}

@test "UT:create_namespace: should delete a namespace that is not 'default'" {
  kubectl (){
    echo "kubectl" $@
  }
  export -f kubectl
  namespace=notdefault
  run deleteNamespace "$namespace"
  assert_output --partial "kubectl delete namespace $namespace"
}

@test "UT:create_namespace: should NOT delete a namespace that is 'default'" {
  kubectl (){
    echo "kubectl $@"
  }
  export -f kubectl
  namespace=default
  run deleteNamespace "$namespace"
  refute_output --partial "kubectl delete namespace $namespace"
}