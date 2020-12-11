#!/usr/bin/env bash

function _run_module_tests() {
  local _here=$(pwd)
  local _module=$1
  local _test_folder=$2
  printf "\n# Running tests for _module %s\n" "$_module"
  cd ../"$_module" && bats -r . --formatter junit --output "$_test_folder"
  cd "$_here"
}
function run_all() {
  local _result_folder=$(pwd)/tmp
  mkdir -p "$_result_folder"
  _run_module_tests junit "$_result_folder"
  _run_module_tests ../azure "$_result_folder"
  _run_module_tests ../kubernetes/bin "$_result_folder"
}
run_all
