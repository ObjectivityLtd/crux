#!/usr/bin/env bash
# if you execute these tests on Windows git bash, make sure you install jq via choco: chocolatey install jq

load $HOME/test/test_helper/bats-assert/load.bash
load $HOME/test/test_helper/bats-support/load.bash

function setup(){
  source "$BATS_TEST_DIRNAME/create_namespace.sh"
}
function teardown(){
  unset kubectl
}

@test "UT:create_namespace: should report when namespace already exists" {
  local _namespace=default
  kubectl (){
      cat << EOF
        NAME              STATUS   AGE
        crux2086          Active   2d2h
        $_namespace        Active   3d1h
        kube-node-lease   Active   3d1h
        kube-public       Active   3d1h
        kube-system       Active   3d1h
EOF
  }
  export -f kubectl
  run create_namespace "$_namespace"
  assert_output --partial "Namespace $_namespace already present"
}

@test "UT:create_namespace: should create namespace if does not exists" {
  local _namespace=test
  kubectl (){
      subcommand=$1
      if [ "$subcommand" == "get" ];then
      cat << EOF
        NAME              STATUS   AGE
        crux2086          Active   2d2h
        kube-node-lease   Active   3d1h
        kube-public       Active   3d1h
        default           Active   3d1h
EOF
    fi
  }
  export -f kubectl
  run create_namespace "$_namespace"
  assert_output "Creating namespace $_namespace"
}