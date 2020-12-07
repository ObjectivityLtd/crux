az login
az account set --subscription "8e945ab5-7b30-4263-aa9e-5d0b985a5bda" #msdn
az group create --name mygroup --location westeurope

#create or update cluster with a specific name
az deployment group create --name temp --resource-group mygroup --template-file k8.json --parameters nodeSize=Standard_D2_v2 nodeCount=2 existingClusterName=k881 clusterNamePrefix=perf
#create a cluster with a unique name in the resource group
#in Azure DevOps it is good to pass BuildDefinition name or id
az deployment group create --name temp --resource-group mygroup --template-file k8.json --parameters nodeSize=Standard_D2_v2 nodeCount=2 clusterNamePrefix=perf

#az group delete --name mygroup --nowait