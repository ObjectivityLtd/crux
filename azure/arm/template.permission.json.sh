#!/bin/bash
template="
{
  \"resource\": {
    \"id\": \"$1\",
    \"type\": \"endpoint\",
    \"name\": \"\"
  },
  \"pipelines\": [],
  \"allPipelines\": {
    \"authorized\": true,
    \"authorizedBy\": null,
    \"authorizedOn\": null
  }
}
"
printf  "$template"