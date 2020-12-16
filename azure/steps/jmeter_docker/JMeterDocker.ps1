param(
  $RootPath="$PSScriptRoot",
  $Image="gabrielstar/crux-master:0.0.1",
  $ContainerName="crux"
)
function Stop-JMeterContainer($ContainerName){
  Write-Host "Cleaning container $ContainerName if running ..."
  docker stop $ContainerName >$null 2>&1
  docker rm $ContainerName >$null 2>&1
}

function Start-JMeterContainer($RootPath, $Image, $ContainerName, $TestDataDir)
{
  Write-Host "Starting container ${ContainerName} from ${Image} ..."
  docker run -d `
          --name ${ContainerName} `
          --entrypoint tail `
          --volume ${TestDataDir}:/test_data ${Image} `
          -f /dev/null
  Write-Host "Started container ${ContainerName} "
  docker ps -a --no-trunc --filter name=^/${ContainerName}$
}
function Execute-CommandInsideDocker($ContainerName, $Command){
  docker exec $ContainerName sh -c "${Command}"
}
function Show-TestDirectory($ContainerName,$Directory){
  Write-Host "Directory ${Directory}:"
  Execute-CommandInsideDocker $ContainerName "ls $Directory"
}
function Start-SimpleTableServer($ContainerName, $DataSetDirectory, $SleepSeconds){
  $stsCommand="screen -A -m -d -S sts /jmeter/apache-jmeter-*/bin/simple-table-server.sh -DjmeterPlugin.sts.addTimestamp=true -DjmeterPlugin.sts.datasetDirectory=${DataSetDirectory}"
  Start-Sleep -Seconds $SleepSeconds
  Execute-CommandInsideDocker $ContainerName "${stsCommand}"
}
function Start-JmeterTest($ContainerName, $JMXPath,$UserArgs,$FixedArgs){
  Write-Host "##[command] sh /jmeter/apache-jmeter-*/bin/jmeter.sh -n -t ${JMXPath} ${UserArgs} ${FixedArgs}"
  Execute-CommandInsideDocker $ContainerName "sh /jmeter/apache-jmeter-*/bin/jmeter.sh -n -t ${JMXPath} ${UserArgs} ${FixedArgs}"
}

function Execute-JMeterTests()
{

  Clear-Host
  Stop-JMeterContainer -ContainerName $ContainerName
  Start-JMeterContainer -RootPath $RootPath -Image $Image -ContainerName $ContainerName -TestDataDir ${PSScriptRoot}/test_data
  Start-SimpleTableServer -ContainerName $ContainerName -DataSetDirectory /test -SleepSeconds 2
  Show-TestDirectory -ContainerName $ContainerName -Directory /test_data
  Start-JmeterTest -ContainerName $ContainerName -JMXPath /test_data/test_table_server.jmx -UserArgs '-Jthreads=10' -FixedArgs '-Gchromedriver=/usr/bin/chromedriver -q /test/user.properties'
  Stop-JMeterContainer -ContainerName $ContainerName
}
Execute-JMeterTests