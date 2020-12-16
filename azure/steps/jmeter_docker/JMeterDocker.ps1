param(
  $RootPath="$PSScriptRoot",
  $Image="gabrielstar/crux:0.0.1",
  $ContainerName="_crux"
)
function Start-JMeterContainer($RootPath, $Image, $ContainerName, $TestDataDir)
{
  Write-Host "Cleaning container $ContainerName if running ..."
  docker stop $ContainerName | Out-Null
  docker rm $ContainerName | Out-Null
  Write-Host "Starting container ${ContainerName} from ${Image} ..."
  docker run -d `
          --name ${ContainerName} `
          --entrypoint tail `
          --volume ${TestDataDir}:/test_data gabrielstar/${Image} `
          -f /dev/null
  Write-Host "Started container ${ContainerName} "
  docker ps -a --no-trunc --filter name=^/${ContainerName}$
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
  Write-Host "##[command] sh /jmeter/apache-jmeter-*/bin/jmeter.sh -n -t ${JMXPath} ${UserArgs} ${FixedArgs}"
  docker exec $ContainerName sh -c "sh /jmeter/apache-jmeter-*/bin/jmeter.sh -n -t ${JMXPath} ${UserArgs} ${FixedArgs}"
}
Clear-Host
Start-JMeterContainer -RootPath $RootPath -Image $Image -ContainerName $ContainerName -TestDataDir ${PSScriptRoot}/test_data
Start-SimpleTableServer -ContainerName crx -DataSetDirectory /test -SleepSeconds 2
Show-TestDirectory -ContainerName crx -DataSetDirectory /test_data
Start-JmeterTest -ContainerName crx -JMXPath /test_data/test_table_server.jmx -UserArgs '-Jthreads=10' -FixedArgs '-Gchromedriver=/usr/bin/chromedriver -q /test/user.properties'