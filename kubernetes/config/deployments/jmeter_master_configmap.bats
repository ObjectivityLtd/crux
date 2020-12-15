#!/usr/bin/env bash

load $HOME/test/test_helper/bats-assert/load.bash
load $HOME/test/test_helper/bats-support/load.bash

setup(){
  source "$BATS_TEST_DIRNAME/jmeter_master_configmap.sh"
  test_tmp_dir=$BATS_TMPDIR
}

@test "UT: load_test should call composing functions" {
  _kill_script() { echo $FUNCNAME; }
  _start_sts() { echo $FUNCNAME; }
  _wait_for_sts() { echo $FUNCNAME; }
  _jmeter() { echo $FUNCNAME; }
  export -f _kill_script _start_sts _wait_for_sts _jmeter
  run load_test
  assert_output --partial _kill_script
  assert_output --partial _start_sts
  assert_output --partial _wait_for_sts
  assert_output --partial _jmeter
}
