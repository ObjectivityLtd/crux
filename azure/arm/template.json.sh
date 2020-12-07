#!/bin/bash
template="
{
  \"data\": {
    \"authorizationType\": \"Kubeconfig\"
  },
  \"name\": \"$1\",
  \"type\": \"kubernetes\",
  \"url\": \"https://$2\",
  \"authorization\": {
    \"parameters\": {
      \"clusterContext\": \"$3\",
      \"kubeConfig\": \"$(az aks get-credentials --name $3 --resource-group $4 -f -)\"},
    \"scheme\": \"Kubernetes\"
  },
  \"isShared\": false,
  \"isReady\": true,
  \"owner\": \"Library\"
}
"
printf  "$template"