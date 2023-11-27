$cultures = [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::AllCultures)

$regions = $cultures
| Where-Object {
    -not $_.IsNeutralCulture
}
| Where-Object {
    -not $_.Equals([System.Globalization.CultureInfo]::InvariantCulture)
}
| ForEach-Object {
    $region = [System.Globalization.RegionInfo]::new($_.Name)
    $region
}
| Where-Object {
    -not [string]::IsNullOrEmpty($_.ISOCurrencySymbol)
}
| Where-Object {
    -not [string]::IsNullOrEmpty($_.CurrencyEnglishName)
}

$currencies = $regions | ForEach-Object {
    [PSCustomObject]@{
        Name                = $_.ISOCurrencySymbol
        CurrencyEnglishName = $_.CurrencyEnglishName
        # CurrencySymbol      = $_.CurrencySymbol
        ISOCurrencySymbol   = $_.ISOCurrencySymbol
        UnicodeSymbol       = $null
    }
}

$currencies = $currencies | Group-Object -Property Name

$currencies = $currencies | ForEach-Object {
    if ($_.Values.Count -ne 1) {
        throw 'Group values have to have one and only one item.'
    }

    for ($i = 0; $i -lt ($_.Group.Count - 1); $i++) {
        for ($j = $i + 1; $j -lt $_.Group.Count; $j++) {
            if ($_.Group[$i].Name -ne $_.Group[$j].Name) {
                throw [PSCustomObject]@{
                    Item1 = $_.Group[$i]
                    Item2 = $_.Group[$j]
                }
            }

            if ($_.Group[$i].CurrencyEnglishName -ne $_.Group[$j].CurrencyEnglishName) {
                throw [PSCustomObject]@{
                    Item1 = $_.Group[$i]
                    Item2 = $_.Group[$j]
                }
            }

            # if ($_.Group[$i].CurrencySymbol -ne $_.Group[$j].CurrencySymbol) {
            #     throw [PSCustomObject]@{
            #         Item1 = $_.Group[$i]
            #         Item2 = $_.Group[$j]
            #     }
            # }

            if ($_.Group[$i].ISOCurrencySymbol -ne $_.Group[$j].ISOCurrencySymbol) {
                throw [PSCustomObject]@{
                    Item1 = $_.Group[$i]
                    Item2 = $_.Group[$j]
                }
            }
        }
    }

    $_.Group[0]
}

$result = Invoke-WebRequest -Uri 'https://www.xe.com/symbols.php'
$result = $result.Content
$bodyStart = $result.IndexOf('<body')
$bodyEnd = $result.IndexOf('</body>') + '</body>'.Length
$body = [xml]$result.Substring($bodyStart, $bodyEnd - $bodyStart)
$currencyUnicodeSymbols = $body
| Select-Xml -XPath '//*[@id="__next"]/div[3]/div[2]/section[2]/section/ul/li'
| Select-Object -Skip 1 # Skip Title Row
| Select-Object -ExpandProperty Node
| ForEach-Object {
    $code = $PSItem | Select-Xml -XPath 'div[3]'
    $code = $code.Node.InnerText

    $unicodeDecimals = $PSItem | Select-Xml -XPath 'div[6]'
    $unicodeDecimals = $unicodeDecimals.Node.InnerText.Split(',', [StringSplitOptions]::TrimEntries) | ForEach-Object { [int]$PSItem }
    $unicodeChars = $unicodeDecimals | ForEach-Object {
        [char]::ConvertFromUtf32( $_ )
    }

    [PSCustomObject]@{
        Code          = $code
        UnicodeSymbol = [string]::new($unicodeChars)
    }
}

foreach ($currencyUnicodeSymbol in $currencyUnicodeSymbols) {
    $currency = $currencies | Where-Object { $PSItem.Name -eq $currencyUnicodeSymbol.Code }
    if ($null -ne $currency) {
        $currency.UnicodeSymbol = $currencyUnicodeSymbol.UnicodeSymbol
    }
}

$currencies = $currencies | ConvertTo-Csv

$currencies | Out-File Currencies.csv
