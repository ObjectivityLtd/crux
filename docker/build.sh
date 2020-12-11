#!/usr/bin/env bash
function _build_all() {
  local _group=$1
  local _prefix=$2
  local _tag=$3
  docker build -t "$_group/$_prefix-base:$_tag" -f Dockerfile .
  docker build -t "$_group/$_prefix-master:$_tag" -f Dockerfile-master .
  docker build -t "$_group/$_prefix-slave:$_tag" -f Dockerfile-slave .
}
function push(){
  local _group=$1
  local _prefix=$2
  local _tag=$3
  docker login
  docker push "$_group/$_prefix-base:$_tag"
  docker push "$_group/$_prefix-master:$_tag"
  docker push "$_group/$_prefix-slave:$_tag"
}
#sh build.sh jmeter-chrome-selenium
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  _build_all gabrielstar crux latest && push gabrielstar crux latest
fi
