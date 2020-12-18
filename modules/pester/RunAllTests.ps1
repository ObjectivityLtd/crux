$env=$args[0]
"running on: $env"
"current location: $(Get-Location)"
"script root: $PSScriptRoot"
"retrieve available modules"

Invoke-Pester -Script "$PSScriptRoot\..\workbooks\*.Tests.ps1" -PassThru -CodeCoverageOutputFile $PSScriptRoot\results\workbook-pesterCoverageTEST.xml -CodeCoverage "$PSScriptRoot\..\workbooks\*.psm1"  -OutputFile $PSScriptRoot\results\workbook-pesterTEST.xml -OutputFormat 'NUnitXML'
Invoke-Pester -Script "$PSScriptRoot\..\..\azure\steps\jmeter_docker\*.Tests.ps1" -PassThru -CodeCoverageOutputFile $PSScriptRoot\results\jmeter_docker-pesterCoverageTEST.xml -CodeCoverage "$PSScriptRoot\..\..\azure\steps\jmeter_docker\*.psm1"  -OutputFile $PSScriptRoot\results\jmeter_docker-pesterTEST.xml -OutputFormat 'NUnitXML'



