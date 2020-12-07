org=gstarczewski
project=jmeter
user=gstarczewski
pat=
path=.
#curl --user $user:$pat -X POST -H "Content-Type: application/json" --data-binary  @../bin/payload.json https://dev.azure.com/$org/$project/_apis/serviceendpoint/endpoints?api-version=5.0-preview.2
bash ../create_service_connection.sh gstarczewski jmeter gstarczewski $pat gabi perf_1334_7ckrfg3tvcc32 jmeter-group ../