#!/bin/bash
delete_service_connection() {
  local org=$1
  local project=$2
  local user=$3
  local pat=$4
  local service_connection_name=$5
  silent=" -s -o /dev/null"
  verbose=" -v"
  opts="$silent"

  service_connection_id=$(curl --user $user:$pat https://dev.azure.com/$org/$project/_apis/serviceendpoint/endpoints?endpointNames=${service_connection_name} | jq '.value[0].id' | sed "s/\"//g")
  if [ -z "$service_connection_id" ]; then
    echo "Cannot get $service_connection_name id. skipping connection deletion as it does not exist."
    return
  fi

  http_code=$(curl $opts -w "%{http_code}" --user $user:$pat -X DELETE https://dev.azure.com/$org/$project/_apis/serviceendpoint/endpoints/${service_connection_id}?api-version=5.1-preview.2)

  echo "Http code: $http_code"
  if [ "$http_code" != "204" ]; then
    echo "Connection $service_connection_name by id $service_connection_id was not deleted."
  else
    echo "Connection $service_connection_name was deleted. "
  fi

}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  delete_service_connection "$@"
fi