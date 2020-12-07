Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope CurrentUser
Set-Location -Path "$HOME\repos\performance\arm-ttk\arm-ttk"
Import-Module .\arm-ttk.psd1
#This runs with pester
Test-AzTemplate -TemplatePath C:\Users\gstarczewski\repos\performance\jmeter_azure_k8_boilerplate\pipelines\azure\arm\k8.json
