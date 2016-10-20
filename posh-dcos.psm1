Push-Location $PSScriptRoot
Write-Host $PSScriptRoot
Get-Help Register-ArgumentCompleter
. .\posh-dcos.ps1
Pop-Location