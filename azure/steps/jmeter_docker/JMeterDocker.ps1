param(
    $RootPath = "$PSScriptRoot",
    $Image = "gabrielstar/crux-master:0.0.1",
    $ContainerName = "crux",
    $JMXPathOnAgent = "${PSScriptRoot}/test_jmx/test_table_server.jmx",
    $TestDataDirOnAgent = "${PSScriptRoot}/test_data",
    $ContainerTestDataDir = "/test",
    $UserArgs = "-Jthreads=10 -Jloops=10",
    $FixedArgs = "-o $ContainerTestDataDir/report -f -l $ContainerTestDataDir/results.csv -e -Gsts=localhost -Gchromedriver=/usr/bin/chromedriver",
    $SleepSeconds = 2,
    $ArtifactsDirectory = "$PSScriptRoot/../../../kubernetes/tmp"
)
Import-Module $PSScriptRoot\JMeterDocker.psm1 -Force

function Start-JMeterTests($RootPath, $Image, $ContainerName, $JMXPathOnAgent, $TestDataDirOnAgent, $ContainerTestDataDir, $UserArgs, $FixedArgs, $SleepSeconds, $ArtifactsDirectory)
{
    $testName = Split-Path $JMXPathOnAgent -leaf
    Copy-Item $JMXPathOnAgent $TestDataDirOnAgent
    Stop-JMeterContainer -ContainerName $ContainerName
    Start-JMeterContainer -RootPath $RootPath -Image $Image -ContainerName $ContainerName -TestDataDir $TestDataDirOnAgent -ContainerTestDataDir $ContainerTestDataDir
    Start-SimpleTableServer -ContainerName $ContainerName -DataSetDirectory $ContainerTestDataDir -SleepSeconds $SleepSeconds
    Show-TestDirectory -ContainerName $ContainerName -Directory $ContainerTestDataDir
    Start-JmeterTest -ContainerName $ContainerName -JMXPath $ContainerTestDataDir/$testName -UserArgs $UserArgs -FixedArgs $FixedArgs
    Show-TestDirectory -ContainerName $ContainerName -Directory $ContainerTestDataDir
    Stop-JMeterContainer -ContainerName $ContainerName
    Copy-Artifacts -ArtifactsDirectory $ArtifactsDirectory `
               -TestDataDirOnAgent $TestDataDirOnAgent
}
Start-JMeterTests -RootPath $RootPath `
                  -Image $Image `
                  -ContainerName $ContainerName `
                  -JMXPathOnAgent $JMXPathOnAgent `
                  -TestDataDirOnAgent $TestDataDirOnAgent `
                  -ContainerTestDataDir $ContainerTestDataDir `
                  -UserArgs $UserArgs `
                  -FixedArgs $FixedArgs `
                  -SleepSeconds $SleepSeconds `
                  -ArtifactsDirectory $ArtifactsDirectory

