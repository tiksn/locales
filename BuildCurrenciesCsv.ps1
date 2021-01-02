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
        throw "Group values have to have one and only one item."
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
$result = $result.Split("`n")
$result = $result[92]
$result = $result.Trim()
$result = $result.Substring("</tr>".Length)
$result = $result.Substring(0, $result.Length - "</table>".Length)
while ($true) {
    $imgIndex = $result.IndexOf("<img")
    if ($imgIndex -lt 0) {
        break;
    }
    $beforeImage = $result.Substring(0, $imgIndex)
    $imageAndTheRest = $result.Remove(0, $imgIndex)
    $imageEndIndex = $imageAndTheRest.IndexOf('>')
    if ($imageEndIndex -ge 0) {
        $afterImage = $imageAndTheRest.Substring($imageEndIndex + 1)
        
        $result = $beforeImage + $afterImage
    }
}
$result = $result.Replace('&nbsp;', ' ')
$result = "<doc> $result </doc>"
$result = [xml]$result

foreach ($node in $result.DocumentElement.ChildNodes) {
    $code = $node.ChildNodes[1].InnerText
    $unicodeDecimals = $node.ChildNodes[5].InnerText.Trim()
    if (-not [string]::IsNullOrEmpty($unicodeDecimals)) {
        $currency = $currencies | Where-Object { $_.Name -eq $code }
        if ($null -ne $currency) {
            $unicodeDecimals = $unicodeDecimals -split ','
            $unicodeDecimals = $unicodeDecimals | ForEach-Object { [int]$_ }
            $unicodeChars = $unicodeDecimals | ForEach-Object {
                [char]::ConvertFromUtf32( $_ )
            }
            $currency.UnicodeSymbol = [string]::new($unicodeChars)
        }
    }
}

$currencies = $currencies | ConvertTo-Csv

$currencies | Out-File currencies.csv
