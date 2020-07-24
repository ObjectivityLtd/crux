#!/usr/bin/env bash
# if you execute these tests on Windows git bash, make sure you install jq via choco: chocolatey install jq

load $HOME/test/test_helper/bats-assert/load.bash
load $HOME/test/test_helper/bats-support/load.bash

function setup(){
  source create_cluster.sh
  az(){
    cat test_data/armResponse.json
  }
  export -f az
}
function teardown(){
  unset az
}

@test "UT:create_cluster: should return name of created cluster" {
  run create_cluster "deployment_name" "resource_group" "template_file" "node_size" "node_count" "cluster_name_prefix" "output_variable"
  assert_output --partial "Cluster name created: perfqinlkwwubxksw"
}

@test "UT:create_cluster: should set output variable to pipeline" {
  run create_cluster "deployment_name" "resource_group" "template_file" "node_size" "node_count" "cluster_name_prefix" "output_variable"
    assert_output --partial "##vso[task.setvariable variable=output_variable]perfqinlkwwubxksw"
}