$cultures = [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::AllCultures)

$countries = $cultures
| Where-Object {
    -not $_.IsNeutralCulture
}
| Where-Object {
    -not $_.Equals([System.Globalization.CultureInfo]::InvariantCulture)
}
| ForEach-Object {
    $country = [System.Globalization.RegionInfo]::new($_.Name)
    $country
}
| Where-Object {
    $_.Name.Length -eq 2
}

$countries = $countries | ForEach-Object {
    $flag = $null
    $twoLetterISOCountryName = $null
    $threeLetterISOCountryName = $null
    $threeLetterWindowsCountryName = $_.ThreeLetterWindowsRegionName

    $nonNumeric = ($_.TwoLetterISORegionName.ToUpperInvariant().ToCharArray() | Where-Object {
            -not [char]::IsDigit($_)
        }).Count -gt 0

    if ($nonNumeric) {
        $twoLetterISOCountryName = $_.TwoLetterISORegionName
        $threeLetterISOCountryName = $_.ThreeLetterISORegionName
    }
    else {
    }

    $flagChars = $_.Name.ToUpperInvariant().ToCharArray() | ForEach-Object {
        [char]::ConvertFromUtf32( $_.ToInt32([System.Globalization.CultureInfo]::InvariantCulture) + 0x1F1A5)
    }

    $flag = [string]::Concat($flagChars)

    if ([string]::IsNullOrWhiteSpace($threeLetterWindowsCountryName)) {
        $threeLetterWindowsCountryName = $null
    }

    if ([string]::IsNullOrWhiteSpace($twoLetterISOCountryName)) {
        $twoLetterISOCountryName = $null
    }

    if ([string]::IsNullOrWhiteSpace($threeLetterISOCountryName)) {
        $threeLetterISOCountryName = $null
    }

    [PSCustomObject]@{
        Name                          = $_.Name
        # DisplayName                  = $_.DisplayName
        EnglishName                   = $_.EnglishName
        # NativeName                   = $_.NativeName
        TwoLetterISOCountryName       = $twoLetterISOCountryName
        ThreeLetterISOCountryName     = $threeLetterISOCountryName
        ThreeLetterWindowsCountryName = $threeLetterWindowsCountryName
        # GeoId                        = $_.GeoId
        # CurrencyEnglishName          = $_.CurrencyEnglishName
        # CurrencyNativeName           = $_.CurrencyNativeName
        # CurrencySymbol               = $_.CurrencySymbol
        # ISOCurrencySymbol            = $_.ISOCurrencySymbol
        # IsMetric                     = [int]$_.IsMetric
        UnicodeFlag                   = $flag
    }
}

$countries = $countries
| Group-Object -Property Name
| ForEach-Object { $_.Group | Select-Object -First 1 }
| Sort-Object -Property Name

$countries = $countries | ConvertTo-Csv

$countries | Out-File Countries.csv
