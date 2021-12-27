# https://github.com/3commas-io/3commas-official-api-docs

$baseUrl = 'https://api.3commas.io'

$root = $psScriptRoot
#$secret = gc $root\secret.txt 
#$key = gc $root\key.txt

function Set-Authentication {
    param(
        [Parameter(Mandatory)][string]$key,
        [Parameter(Mandatory)][string]$secret
    )
    $script:key = $key
    $script:secret = $secret
}

function getsig {
    param(
        $urlWithQuery,
        $secret
    )
    Write-Debug "Computing signature"
    Write-Debug " Secret:  '$secret'"
    Write-Debug " Url:     '$urlWithQuery'"

    $hmacsha = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha.key = [Text.Encoding]::ASCII.GetBytes($secret)
    $signature = $hmacsha.ComputeHash([Text.Encoding]::ASCII.GetBytes($urlWithQuery))
    $null = $hmacsha.Dispose()

    $ret = -join $signature.Foreach{$_.ToString('x2')}
    Write-Debug " Result:     '$ret'"
    $ret
}

function Get-Pingpong {
    Invoke-WebRequest "$baseUrl/public/api/ver1/ping" | % Content | ConvertFrom-Json
}

function Get-ServerTime {
    Invoke-WebRequest "$baseUrl/public/api/ver1/time" | % Content | ConvertFrom-Json | % { [System.DateTimeOffset]::FromUnixTimeSeconds($_.server_time) }
}

function makeRawAuthGetRequest {
    [cmdletbinding()]
    param($urlpart, $queryString = '')
    $urlPartWithQuery = $queryString ? "$($urlpart)?$queryString" : $urlpart

    $attempts = 1
    while($attempts -le 10) {
        $res = Invoke-WebRequest -Method GET -Uri "$baseUrl$urlPartWithQuery" -Headers @{ APIKEY = $key; Signature = (getsig $urlPartWithQuery $secret) } -SkipHttpErrorCheck
        if ($res.StatusCode -eq 200) {
            return $res.Content | ConvertFrom-Json -NoEnumerate
        }
        if ($res.StatusCode -eq 429) {
            Write-Host (Get-Date) Rate limited! ($res.Content)
            Start-Sleep -sec ($attempts * 2)
            $attempts++
            continue
        }
        if ($res.StatusCode -eq 418) {
            throw "$(Get-Date) Banned! Stop api calls. Content: $($res.Content)"
        }
        if (Get-Member -Name error -EA SilentlyContinue) {
            Write-Host "$(Get-Date) Error. Trying again. Content: $($res.Content)"
        }
    }
    throw "$(Get-Date) Unable to get result for '$urlPart/$queryString'"
}


function makeAuthGetRequestAllPaged {
    [cmdletbinding()]
    param($urlpart, $queryString = '', $pageSize = 50)
    
    $page = 0
    $queryString = $queryString ? "&$queryString" : ''
    while($true) {
        $page++
        $qsWithPage = "page=$page&per_page=$pageSize$queryString"
        $response = makeRawAuthGetRequest -urlpart $urlpart -queryString $qsWithPage
        if (!$response -or ($response -is 'array' -and $response.Count -eq 0)) {
            break
        }

        if ($response -is 'array') {
            $response
            if ($response.Count -lt $pageSize) {
                break
            }
        } else {
            $response
        }
    }
}

function Get-SmartTrades {
    #makeRawAuthGetRequest -urlpart '/public/api/v2/smart_trades'
    makeAuthGetRequestAllPaged -urlpart '/public/api/v2/smart_trades'
}

function Get-SmartTrade {
    param(
        [Parameter(Mandatory)][string]$id
    )
    makeRawAuthGetRequest -urlpart "/public/api/v2/smart_trades/$id"
}

function Get-TradeStatusIsActive {
    param(
        [Parameter(Mandatory)][string]$status
    )
    $status -notmatch '^(finished|cancelled|stop_loss_finished|panic_sold|failed)'
}


Export-ModuleMember Get-SmartTrades, Get-SmartTrade, Get-Pingpong, Get-ServerTime, Set-Authentication, Get-TradeStatusIsActive