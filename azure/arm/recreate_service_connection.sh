#!/bin/bash
recreate_service_connection() {
  local org=$1
  local project=$2
  local user=$3
  local pat=$4
  local name=$5
  local cluster_name=$6
  local resource_group=$7
  local path=$8
  source "$path"/delete_service_connection.sh
  source "$path"/create_service_connection.sh
  delete_service_connection "$org" "$project" "$user" "$pat" "$name"
  create_service_connection "$org" "$project" "$user" "$pat" "$name" "$cluster_name" "$resource_group" "$path"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  recreate_service_connection "$@"
fi