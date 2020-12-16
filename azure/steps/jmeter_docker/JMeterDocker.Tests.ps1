Import-Module $PSScriptRoot\JMeterDocker.psm1 -Force
$script:testDir = "$PSScriptRoot\test_data"

Describe "Script Tests"  {
    Context -Name 'When I try to convert non-existing file'{


        It "should not throw exception"  {

        }

    }
}
<#
    These are modules tests so we use specific scope

#>
InModuleScope JMeterDocker{
    Describe "Module Tests" {
        BeforeAll {

        }
        BeforeEach {

        }
        Context 'When I run Send-RawDataToLogAnalytics' {
            It "should run Send-LogAnalyticsData once exactly" {

            }
            It "should run Read-Properties once exactly" {

            }
        }
    }
}
