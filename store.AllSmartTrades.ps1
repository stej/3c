param(
    [Parameter(Mandatory)][string]$key,
    [Parameter(Mandatory)][string]$secret,
    [Parameter(Mandatory)][string]$outputFilePath
)

Import-Module $PsScriptRoot\3c.psm1 -force
Set-Authentication -key $key -secret $secret

Get-SmartTrades | 
    ConvertTo-Json -depth 100 | 
    Set-Content $outputFilePath