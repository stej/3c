param(
    [Parameter(Mandatory)][string]$inputFilePath,      # input file with smart trades (json)
    [Parameter()][string]$coin,                        # e.g. THETA
    [Parameter()][switch]$onlyActive,                  # shows only rows that are not Cancelled, Finished, Closed, Failed, Sold
    [Parameter()][switch]$withOrderType                # shows order type - M as Market, L as limit
)

Import-Module $PsScriptroot\3c.psm1 -force

$trades = Get-Content $inputFilePath | ConvertFrom-Json

# expected max 5 TPs, if there are more, warn user
function WarnIfThereAreMoreTPs {
    $maximalCountOfTPs = $trades.take_profit | Foreach-Object { $_.steps.Count } | Sort-Object | Select-Object -last 1
    if ($maximalCountOfTPs -gt 5) {
        Write-Warning "This script assumes only max 5 TPs for smart trades. It's pretty easy to adjust this script, so go on."
        Write-Warning "Trades with more than 5 TPs:"
        $trades | 
            Where-Object { $_.take_profit.steps.Count -gt 5 } | 
            Where-Object { !$coin -or $_.Pair -match $coin } |
            Where-Object { !$onlyActive -or (Get-TradeStatusIsActive $_.status.type) } |
            Foreach-Object { [pscustomobject] @{
                    Id = $_.Id
                    DateCreated = $_.data.created_at
                    DateClosed = $_.data.closed_at
                    Exchange = $_.account.name
                    Pair = $_.pair
                    Status = $_.status.type
                    TPStepsCount = $_.take_profit.steps.Count
                    Note = $_.note -split "`n" -join '|'
                }
            } |
            Sort-Object DateCreated |
            Format-Table -auto 
        Write-Host "-----------------------------------"
    }
}

function formatstep {
    param($step)
    #"{0}{1},{2}% {3}" -f $step.position, $step.order_type[0], $step.volume, ($step.trailing.enabled ? 'TRAIL' : '')
    $trail = $step.trailing
    $orderType = $withOrderType ? "$($step.order_type[0].ToString().ToUpper()):" : ''
    "{0}{1}%{2}" -f $orderType, $step.volume, ($trail.enabled ? ",Trail$($trail.percent -replace '\.0+$', '')%" : '')
}
function formatsl {
    param($sl)
    $orderType = $withOrderType ? "$($sl.order_type.ToString().ToUpper()):" : ''
    
    # limit price; $sl.price.value means value when SL is activated
    if ($sl.order_type -eq 'limit') {
        if (!$sl.price.value) { Write-Warning "Unexpected. $($sl | out-string)" }
        "{0}{1}->{2}" -f $orderType, $sl.price.value, $sl.conditional.price.value 
    } else {
        $trailing = $sl.conditional.trailing.enabled ? ',Trail' : ''
        if ($trailing -and $sl.conditional.trailing.percent) {
            $trailing += "$($sl.conditional.trailing.percent -replace '\.0+$', '')%"
        }
        "{0}{1}{2}{3}" -f $orderType, $sl.conditional.price.value, ($sl.breakeven ? ',Brkevn' : ''), $trailing
    }
}
function shortenPrice {
    param([string]$price)
    $price -replace '^0+\.', '.' -replace '\.0+$', ''
}

function GetTPs {
    $trades |
        Where-Object { !$coin -or $_.Pair -match $coin } |
        Where-Object { !$onlyActive -or (Get-TradeStatusIsActive $_.status.type) } |
        Foreach-Object { 
            $steps = $_.take_profit.steps  | Sort-Object -property {$_.price.value }
            $tpSet = $_.take_profit.enabled
            $sl = $_.stop_loss
            $slSet = $sl.enabled
            [pscustomobject] @{
                Id = $_.Id
                DateCreated = $_.data.created_at
                Exchange = $_.account.name
                Pair = $_.pair
                TP1 = $tpSet -and $steps.Count -gt 0 ? (formatstep $steps[0]) : ''
                TPPrice1 = $tpSet -and $steps.Count -gt 0 ? (shortenPrice $steps[0].price.value) : ''
                
                TP2 = $tpSet -and $steps.Count -gt 1 ? (formatstep $steps[1]) : ''
                TPPrice2 = $tpSet -and $steps.Count -gt 0 ? (shortenPrice $steps[1].price.value) : ''
                
                TP3 = $tpSet -and $steps.Count -gt 2 ? (formatstep $steps[2]) : ''
                TPPrice3 = $tpSet -and $steps.Count -gt 0 ? (shortenPrice $steps[2].price.value) : ''
                
                TP4 = $tpSet -and $steps.Count -gt 3 ? (formatstep $steps[3]) : ''
                TPPrice4 = $tpSet -and $steps.Count -gt 0 ? (shortenPrice $steps[3].price.value) : ''
                
                TP5 = $tpSet -and $steps.Count -gt 4 ? (formatstep $steps[4]) : ''
                TPPrice5 = $tpSet -and $steps.Count -gt 0 ? (shortenPrice $steps[4].price.value) : ''
                
                SL = $slSet ? (formatsl $_.stop_loss) : ''
                SLTimeout = $slSet -and $sl.timeout.enabled ? "$($sl.timeout.value)s" : ''
            }
        } |
        Sort-Object DateCreated |
        #Select-Object Id, DateCreated, Exchange, Pair, TP1, TPPrice1, TP2, TPPrice2, TP3, TPPrice3, TP4, TPPrice4, TP5, TPPrice5, SL, SLTimeout
        Select-Object Id, DateCreated, Exchange, Pair, TP1, TP2, TP3, TP4, TP5, TPPrice1, TPPrice2, TPPrice3, TPPrice4, TPPrice5, SL, SLTimeout
}


WarnIfThereAreMoreTPs
Write-Host "TPs are sorted by Price! It means that if you set in 3c TP1 10$, TP2 8$ and TP3 12$, they will be sorted. Output TPs will be 8$, 10$, 12$"
GetTPs | Format-Table -auto *