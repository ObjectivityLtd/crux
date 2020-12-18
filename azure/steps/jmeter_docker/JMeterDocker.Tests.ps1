BeforeAll{
    Import-Module $PSScriptRoot/JMeterDocker.psm1 -Force
    . $PSScriptRoot/JMeterDocker.ps1 -Force -SkipRun $TRUE #import w/o execution
}
Describe "Script Tests" {
    Context "When Start-JMeterTests is run" {
            BeforeAll {
                #all of these should be executed
                Mock -CommandName Split-Path { } -Verifiable
                Mock -CommandName Write-Host { } -Verifiable
                Mock -CommandName Copy-Item { } -Verifiable
                Mock Stop-JMeterContainer { } -Verifiable
                Mock Start-JMeterContainer -Verifiable
                Mock Start-JmeterTest -Verifiable
                Mock Start-SimpleTableServer -Verifiable
                Mock Show-TestDirectory -Verifiable
                Mock Copy-Artifacts -Verifiable
                #default variables are loaded up
                Start-JMeterTests  `
                  -Image $Image `
                  -ContainerName $ContainerName `
                  -JMXPathOnAgent $JMXPathOnAgent `
                  -TestDataDirOnAgent $TestDataDirOnAgent `
                  -ContainerTestDataDir $ContainerTestDataDir `
                  -UserArgs $UserArgs `
                  -FixedArgs $FixedArgs `
                  -SleepSeconds $SleepSeconds `
                  -ArtifactsDirectory $ArtifactsDirectory `
                  -SkipRun $FALSE
            }
            It "should execute Write-Host with Running message"  {
                Assert-MockCalled Write-Host -Scope Context -ParameterFilter { $Object -eq "Running" }
            }
            It "should verifiable mocks be called"  {
                Should -InvokeVerifiable
            }
            It "should Stop-JMeterContainer be called twice exactly"  {
                Should -Invoke Stop-JMeterContainer -Scope Context -ModuleName JMeterDocker -Times 2
            }
            It "should all script variables have default values"  {
                $variables =@(
                                $Image,
                                $ContainerName,
                                $JMXPathOnAgent,
                                $TestDataDirOnAgent,
                                $ContainerTestDataDir,
                                $UserArgs,
                                $FixedArgs,
                                $SleepSeconds,
                                $ArtifactsDirectory,
                                $SkipRun)
                foreach($variable in $variables){
                    $variable | Should -Not -BeNullOrEmpty
                }
            }

    }
    Context "When Start-JMeterTests is run with SkipRun" {
        BeforeAll {
            Mock Write-Host { }
            Start-JMeterTests  `
                  -Image $Image `
                  -ContainerName $ContainerName `
                  -JMXPathOnAgent $JMXPathOnAgent `
                  -TestDataDirOnAgent $TestDataDirOnAgent `
                  -ContainerTestDataDir $ContainerTestDataDir `
                  -UserArgs $UserArgs `
                  -FixedArgs $FixedArgs `
                  -SleepSeconds $SleepSeconds `
                  -ArtifactsDirectory $ArtifactsDirectory `
                  -SkipRun $TRUE
        }
        It "should  execute Write-Host with Skipped message"  {
           Assert-MockCalled Write-Host -Scope Context -ParameterFilter { $Object -eq "Skipped" }
        }
    }
    Context "When Start-JMeterTests is run without mocks" -Tag E2E {
        BeforeAll {
            Start-JMeterTests `
                  -Image $Image `
                  -ContainerName $ContainerName `
                  -JMXPathOnAgent $JMXPathOnAgent `
                  -TestDataDirOnAgent $TestDataDirOnAgent `
                  -ContainerTestDataDir $ContainerTestDataDir `
                  -UserArgs $UserArgs `
                  -FixedArgs $FixedArgs `
                  -SleepSeconds $SleepSeconds `
                  -ArtifactsDirectory $ArtifactsDirectory `
                  -SkipRun $FALSE
        }
        It "should  execute Write-Host with Skipped message"  {
            $TRUE
        }
    }
}

Describe "Module Tests" {
        BeforeAll {
        }
        It "should Copy-Artifacts execute Copy-Item 4 times exactly"  {
            Mock Copy-Item
            Copy-Artifacts
            Assert-MockCalled Copy-Item -Scope It -Times 4 -Exactly
        }
}
