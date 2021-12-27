param(
    [Parameter(Mandatory)][string]$inputFilePath,      # input file with smart trades (json)
    [Parameter()][string]$coin,                        # e.g. THETA
    [Parameter()][switch]$table,                       # shows as table
    [Parameter()][switch]$onlyActive                   # shows only rows that are not Cancelled, Finished, Closed, Failed, Sold
)

Import-Module $PsScriptroot\3c.psm1 -force

$data = 
    Get-Content $inputFilePath | 
    ConvertFrom-Json |
    % { 
        [pscustomobject] @{
            Id = $_.Id
            DateCreated = $_.data.created_at
            DateClosed = $_.data.closed_at
            Exchange = $_.account.name
            Pair = $_.pair
            Status = "{0}({1})" -f $_.status.type, $_.status.title
            Position = $_.position.total.value
            TPEnabled = $_.take_profit.enabled
            SLEnabled = $_.stop_loss.enabled
            Profit = $_.profit.percent
            Note = $_.note -split "`n" -join '|'
        }
    } |
    ? { !$coin -or $_.Pair -match $coin } |
    ? { !$onlyActive -or (Get-TradeStatusIsActive $_.Status) } |
    Sort-Object DateCreated

if ($table) { 
    $data | Format-Table -auto *
} else {
    $data | Format-List
}