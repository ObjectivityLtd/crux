#!/usr/bin/env bash

function runModuleTests(){
 local here=$(pwd)
 local module=$1
 local test_folder=$2
 printf "\n# Running tests for module $module\n"
 cd ../$module && bats -r . --formatter junit --output "$test_folder"
 cd "$here"
}
function sourceLibs(){
  source $1
}
function runAll(){
  sourceLibs "../../azure/lib/*.sh"
  result_folder=$(pwd)/tmp
  mkdir -p "$result_folder"
  runModuleTests junit "$result_folder"
  runModuleTests ../azure "$result_folder"
  runModuleTests ../kubernetes/bin "$result_folder"
}

runAll