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

$regions = $regions | ForEach-Object {
    $flag = $null
    $twoLetterISORegionName = $null
    $threeLetterISORegionName = $null
    $threeLetterWindowsRegionName = $_.ThreeLetterWindowsRegionName
    $m49 = $null

    $nonNumeric = ($_.TwoLetterISORegionName.ToUpperInvariant().ToCharArray() | Where-Object {
            -not [char]::IsDigit($_)
        }).Count -gt 0

    if ($nonNumeric) {
        $twoLetterISORegionName = $_.TwoLetterISORegionName
        $threeLetterISORegionName = $_.ThreeLetterISORegionName
    }
    else {
        $m49 = $_.Name
    }

    if ($_.Name -eq '001') {
        $flagChars = @(0x1F1FA, 0x1F1F3) | ForEach-Object {
            [char]::ConvertFromUtf32( $_ )
        }

        $flag = [string]::Concat($flagChars)

    }
    elseif ($_.Name -eq '029') {

    }
    elseif ($_.Name -eq '150') {
        $flagChars = @(0x1F1EA, 0x1F1FA) | ForEach-Object {
            [char]::ConvertFromUtf32( $_ )
        }

        $flag = [string]::Concat($flagChars)
    }
    elseif ($_.Name -eq '419') {

    }
    else {
        $flagChars = $_.Name.ToUpperInvariant().ToCharArray() | ForEach-Object {
            [char]::ConvertFromUtf32( $_.ToInt32([System.Globalization.CultureInfo]::InvariantCulture) + 0x1F1A5)
        }

        $flag = [string]::Concat($flagChars)
    }

    if ([string]::IsNullOrWhiteSpace($threeLetterWindowsRegionName)) {
        $threeLetterWindowsRegionName = $null
    }

    if ([string]::IsNullOrWhiteSpace($twoLetterISORegionName)) {
        $twoLetterISORegionName = $null
    }

    if ([string]::IsNullOrWhiteSpace($threeLetterISORegionName)) {
        $threeLetterISORegionName = $null
    }
    
    [PSCustomObject]@{
        Name                         = $_.Name
        # DisplayName                  = $_.DisplayName
        EnglishName                  = $_.EnglishName
        # NativeName                   = $_.NativeName
        TwoLetterISORegionName       = $twoLetterISORegionName
        ThreeLetterISORegionName     = $threeLetterISORegionName
        M49                          = $m49
        ThreeLetterWindowsRegionName = $threeLetterWindowsRegionName
        # GeoId                        = $_.GeoId
        # CurrencyEnglishName          = $_.CurrencyEnglishName
        # CurrencyNativeName           = $_.CurrencyNativeName
        # CurrencySymbol               = $_.CurrencySymbol
        # ISOCurrencySymbol            = $_.ISOCurrencySymbol
        # IsMetric                     = [int]$_.IsMetric
        UnicodeFlag                  = $flag
    }
}

$regions = $regions | Group-Object -Property Name

$regions = $regions | ForEach-Object {
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

            # if ($_.Group[$i].EnglishName -ne $_.Group[$j].EnglishName) {
            #     throw [PSCustomObject]@{
            #         Item1 = $_.Group[$i]
            #         Item2 = $_.Group[$j]
            #     }
            # }

            if ($_.Group[$i].TwoLetterISORegionName -ne $_.Group[$j].TwoLetterISORegionName) {
                throw [PSCustomObject]@{
                    Item1 = $_.Group[$i]
                    Item2 = $_.Group[$j]
                }
            }

            if ($_.Group[$i].ThreeLetterISORegionName -ne $_.Group[$j].ThreeLetterISORegionName) {
                throw [PSCustomObject]@{
                    Item1 = $_.Group[$i]
                    Item2 = $_.Group[$j]
                }
            }

            if ($_.Group[$i].ThreeLetterWindowsRegionName -ne $_.Group[$j].ThreeLetterWindowsRegionName) {
                throw [PSCustomObject]@{
                    Item1 = $_.Group[$i]
                    Item2 = $_.Group[$j]
                }
            }

            # if (($_.Group[$i].GeoId) -ne ($_.Group[$j].GeoId)) {
            #     throw [PSCustomObject]@{
            #         Item1 = $_.Group[$i]
            #         Item2 = $_.Group[$j]
            #     }
            # }

            # if ($_.Group[$i].IsMetric -ne $_.Group[$j].IsMetric) {
            #     throw [PSCustomObject]@{
            #         Item1 = $_.Group[$i]
            #         Item2 = $_.Group[$j]
            #     }
            # }
        }
    }

    $_.Group[0]
}

$regions = $regions | ConvertTo-Csv

# $regions

$regions | Out-File regions.csv
