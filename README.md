# 3c
Very simple 3commas helper for basic overview of smart trades.
Written in PowerShell script so everyone can check there is no smart backdoor. It just simply calls read-only api and saves data to disk. Nothing more. 

Tested in PowerShell 7.2.0. Will probably work well in all Core versions of PowerShell. 

## Prerequisities

Original 3c doc is located here: https://github.com/3commas-io/3commas-official-api-docs

You need to create api key and secret at 3commas web. See https://3commas.io/api_access_tokens. Read-only access for smart trades is enough. 
Save the key/secret into separate files for later use.

## Download smart trades

```
cd 3c
.\store.AllSmartTrades.ps1 -key 'my api key' -secret 'my secret' -outputFilePath mytrades.json

# or you might use the secrets from file:
.\store.AllSmartTrades.ps1 -key (Get-Content .\key.txt) -secret (Get-Content .\secret.txt) -outputFilePath mytrades.json
```

This will save all the smart trades into json file. Paging is used. Tested on something over 100 trades. Not sure whether thousands will be ok or you will hit some DOS protection.

## Print smart trades summary

This will list all the trades.
```
cd 3c
.\print.AllSmartTradesSummary.ps1 -inputFilePath .\mytrades.json
```

If you would like to see only the active ones, possibly in a table for better overview, add appropriate switches:

```
.\print.AllSmartTradesSummary.ps1 -inputFilePath .\mytrades.json -onlyActive -table
```

Filtering by coin is supported.

```
.\print.AllSmartTradesSummary.ps1 -inputFilePath .\mytrades.json -table -coin DUSK
```

Sample output:
```
3c on main |243ms| ➜  .\print.AllSmartTradesSummary.ps1 -inputFilePath .\mytrades.json -table -coin DUSK

      Id DateCreated         DateClosed          Exchange Pair      Status                                 Position     TPEnabled SLEnabled Profit Note
      -- -----------         ----------          -------- ----      ------                                 --------     --------- --------- ------ ----
11038704 2021-12-16 07:56:37                     Binance  USDT_DUSK waiting_targets(Waiting Targets)       278.80194475      True     False 25.03  2021-12-16|bought fo...
11321805 2021-12-25 09:55:59 2021-12-27 09:02:52 Binance  USDT_DUSK panic_sold(Closed at Market Price)     99.670697         True     False -1.23  2021-12-25|this is f...
11353274 2021-12-26 18:37:12 2021-12-26 20:13:51 Binance  USDT_DUSK stop_loss_finished(Stop Loss finished) 300.07068435      True      True -1.3   2012-12-26|again som...
```

## Print TP/SL summary

Might be useful for quick overview whether you have set all TPs and SLs properly or not. Also if you close your orders at the end of the year because of realized losses, 
this might help you during reopening the trades next morning.

```
3c on main |195ms| ➜  .\print.AllSmartTrades.TpSl.ps1 -inputFilePath .\mytrades.json -onlyActive
TPs are sorted by Price! It means that if you set in 3c TP1 10$, TP2 8$ and TP3 12$, they will be sorted. Output TPs will be 8$, 10$, 12$

      Id DateCreated         Exchange Pair       TP1             TP2            TP3            TP4            TP5            TPPrice1 TPPrice2 TPPrice3 TPPrice4 TPPrice5 SL            SLTimeout
      -- -----------         -------- ----       ---             ---            ---            ---            ---            -------- -------- -------- -------- -------- --            ---------
11924526 2021-12-06 11:30:55 Binance  USDT_ICP
12013978 2021-12-09 19:33:48 Binance  USDT_FTT   100.0%                                                                      43.97
12031129 2021-12-10 14:59:09 FTX      USDT_LTC
12031723 2021-12-10 15:25:47 Kucoin   USDT_VAI
12251987 2021-12-22 09:11:07 Binance  USDT_BAL   25.0%           25.0%          25.0%          25.0%,Trail-3%                18.57    20.88    22.57    24.51
12291467 2021-12-23 21:25:30 Kucoin   USDT_THETA 50.0%           50.0%,Trail-3%                                              5.8786   6.5405                              5.4688,Trail
12355056 2021-12-26 23:00:43 Binance  USDT_FTM   35.0%           65.0%                                                       2.4869   2.6218                              2.136         300s
12355251 2021-12-26 23:15:34 Binance  USDT_ALGO  30.0%           35.0%          35.0%                                        1.7093   1.7835   1.8122                     1.5253        120s
```