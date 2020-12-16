param(
  $RootPath="$PSScriptRoot",
  $Image="gabrielstar/crux:0.0.1"
)
function Start-JMeterContainer($RootPath, $Image, $TestDataDir)
{
  Write-Host "Cleaning container if running"
  docker stop crx
  docker rm crx
  Write-Host "Starting container ${Image}"
  docker run -d `
          --name crx `
          --entrypoint tail `
          --volume ${TestDataDir}:/test_data gabrielstar/crux-master:0.0.1 `
          -f /dev/null
  Write-Host "Started container: "
  docker ps -a --no-trunc --filter name=^/crx$
}
function Show-TestDirectory($Directory){
  Write-Host "Directory ${Directory}:"
  docker exec crx sh -c "ls $Directory"
}
function Start-SimpleTableServer($ContainerName, $DataSetDirectory, $SleepSeconds){
  $stsCommand="screen -A -m -d -S sts /jmeter/apache-jmeter-*/bin/simple-table-server.sh -DjmeterPlugin.sts.addTimestamp=true -DjmeterPlugin.sts.datasetDirectory=${DataSetDirectory}"
  Start-Sleep -Seconds $SleepSeconds
  docker exec $ContainerName sh -c "${stsCommand}"
}
function Start-JmeterTest($ContainerName, $JMXPath,$UserArgs,$FixedArgs){
  Write-Host "Running: sh /jmeter/apache-jmeter-*/bin/jmeter.sh -n -t ${JMXPath} ${UserArgs} ${FixedArgs}"
  docker exec $ContainerName sh -c "sh /jmeter/apache-jmeter-*/bin/jmeter.sh -n -t ${JMXPath} ${UserArgs} ${FixedArgs}"
}
Clear-Host
Start-JMeterContainer -RootPath $RootPath -Image $Image -TestDataDir ${PSScriptRoot}/test_data
Start-SimpleTableServer -ContainerName crx -DataSetDirectory /test -SleepSeconds 2
Show-TestDirectory -ContainerName crx -DataSetDirectory /test_data
Start-JmeterTest -ContainerName crx -JMXPath /test_data/test_table_server.jmx -UserArgs '-Jthreads=10' -FixedArgs '-Gchromedriver=/usr/bin/chromedriver -q /test/user.properties'