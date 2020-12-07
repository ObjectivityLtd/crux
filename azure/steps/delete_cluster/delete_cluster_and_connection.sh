#!/bin/bash
delete_cluster_and_connection() {
  local path=$1
  local cluster_name=$2
  local resource_group=$3
  local org=$4
  local project=$5
  local user=$6
  local pat=$7
  local connection_name=$8
  local skipConnectionDeletion=$9

  source "$path"/delete_cluster.sh
  delete_cluster "$cluster_name" "$resource_group"

  if [ -z "$skipConnectionDeletion" ];then
    echo "Skipping connection deletion"
  else
    source "$path"/delete_service_connection.sh
    delete_service_connection "$org" "$project" "$user" "$pat" "$connection_name"
  fi
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  delete_cluster_and_connection "$@"
fi