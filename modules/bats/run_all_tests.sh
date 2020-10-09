#!/usr/bin/env bash

function runModuleTests(){
 local here=$(pwd)
 local module=$1
 local test_folder=$2
 printf "\n# Running tests for module $module\n"
 cd ../$module && bats --formatter junit *.bats --output "$test_folder"
 cd "$here"
}

function runAll(){
  result_folder=$(pwd)/tmp
  mkdir -p "$result_folder"
  runModuleTests junit "$result_folder"
  runModuleTests ../pipelines/azure/arm "$result_folder"
  runModuleTests ../kubernetes/bin "$result_folder"
}

runAll