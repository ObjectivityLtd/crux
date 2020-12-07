#!/bin/bash
create_service_connection() {
  local org=$1
  local project=$2
  local user=$3
  local pat=$4
  local name=$5
  local cluster_name=$6
  local resource_group=$7
  local path=$8

  url=$(az aks show --name "$cluster_name" --resource-group "$resource_group" | jq '.fqdn' | sed "s/\"//g") || :
  printf "Creating kubernetes connection $name for cluster: $cluster_name \n\t url: $url"
  source "$path"/template.json.sh $name $url $cluster_name $resource_group >"$path"/payload.json
  ls
  echo "Sending payload"
  cat "$path"/payload.json
  #Create connection
  #http_code=$(curl -s -o /dev/null -w "%{http_code}" --user $user:$pat -X POST -H "Content-Type: application/json" --data-binary  @$path/payload.json https://dev.azure.com/$org/$project/_apis/serviceendpoint/endpoints?api-version=5.0-preview.2)
  http_code=$(curl --user $user:$pat -X POST -H "Content-Type: application/json" --data-binary @"$path"/payload.json https://dev.azure.com/$org/$project/_apis/serviceendpoint/endpoints?api-version=5.0-preview.2)
  id=$(printf "$http_code" | jq -r '.id')
  echo "Resource ID: $id"

  #permission all pipelines
  source "$path"/template.permission.json.sh $id >"$path"/payload.permission.json
  #Request URL: https://dev.azure.com/gstarczewski/a4107a63-77ef-47fa-9546-9e28d01930cb/_apis/pipelines/pipelinePermissions/endpoint/cbe8ef9a-9adb-49dc-8115-aa4926b64c5f
  output=$(curl --user $user:$pat -X PATCH -H "Content-Type: application/json" -H "Accept:api-version=5.1-preview.1" --data-binary @"$path"/payload.permission.json https://dev.azure.com/$org/$project/_apis/pipelines/pipelinePermissions/endpoint/$id)
  echo $output
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  create_service_connection "$@"
fi
