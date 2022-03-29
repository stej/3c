param(
    [Parameter(Mandatory)][string]$inputFilePath,      # input file with smart trades (json)
    [Parameter()][string]$coin,                        # e.g. THETA
    [Parameter()][switch]$table,                       # shows as table
    [Parameter()][switch]$onlyActive,                  # shows only rows that are not Cancelled, Finished, Closed, Failed, Sold
    [Parameter()][switch]$groupByStatus                # groups output by status (Cancelled, ...)
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
            Fin        = $_.data.finished ? '✓' : ''
            Exchange = $_.account.name
            Pair = $_.pair
            Status = "{0}({1})" -f $_.status.type, $_.status.title
            Position = $_.position.total.value
            TP = $_.take_profit.enabled ? '✓' : ''
            SL = $_.stop_loss.enabled ? '✓' : ''
            'Profit%' = $_.profit.percent
            Note = $_.note -split "`n" -join '|'
        }
    } |
    ? { !$coin -or $_.Pair -match $coin } |
    ? { !$onlyActive -or (Get-TradeStatusIsActive $_.Status) } |
    Sort-Object DateCreated


$command     = $table ? (Get-Command 'Format-Table') : (Get-Command 'Format-List')
$commandargs = $table ? @{ Auto = $true; Property = '*' } : @{}
if ($groupByStatus) {
    $data | 
        Group-Object Status | 
        % { Write-Host "-------- $($_.Name) --------" -fore Green
            $group = $_.Group | Sort-Object DateCreated
            & $command -input $group @commandargs
       }
} else {
    & $command -input $data @commandargs
}