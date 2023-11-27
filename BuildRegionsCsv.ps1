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
        Parent                       = $null
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

$methodology = Get-Content -Path '.\UNSD-Methodology.csv' | ConvertFrom-Csv
$m49Codes = @()

$m49Codes += $methodology
| ForEach-Object {
    [PSCustomObject]@{
        code    = $_.'Global Code'
        name    = $_.'Global Name'
        iso3166 = $null
        parent  = $null
    }
}
| Sort-Object -Property code
| Get-Unique -AsString

$m49Codes += $methodology
| Where-Object { $_.'Region Code' }
| ForEach-Object {
    [PSCustomObject]@{
        code    = $_.'Region Code'
        name    = $_.'Region Name'
        iso3166 = $null
        parent  = $_.'Global Code'
    }
}
| Sort-Object -Property code
| Get-Unique -AsString

$m49Codes += $methodology
| Where-Object { $_.'Sub-region Code' }
| ForEach-Object {
    [PSCustomObject]@{
        code    = $_.'Sub-region Code'
        name    = $_.'Sub-region Name'
        iso3166 = $null
        parent  = $_.'Region Code'
    }
}
| Sort-Object -Property code
| Get-Unique -AsString

$m49Codes += $methodology
| Where-Object { $_.'Intermediate Region Code' }
| ForEach-Object {
    [PSCustomObject]@{
        code    = $_.'Intermediate Region Code'
        name    = $_.'Intermediate Region Name'
        iso3166 = $null
        parent  = $_.'Sub-region Code'
    }
}
| Sort-Object -Property code
| Get-Unique -AsString

$m49Codes += $methodology
| Where-Object { -not $_.'Intermediate Region Code' -and $_.'Sub-region Code' }
| ForEach-Object {
    [PSCustomObject]@{
        code    = $_.'M49 Code'
        name    = $_.'Country or Area'
        iso3166 = $_.'ISO-alpha3 Code'
        parent  = $_.'Sub-region Code'
    }
}
| Sort-Object -Property code
| Get-Unique -AsString

$m49Codes += $methodology
| Where-Object { -not $_.'Intermediate Region Code' -and -not $_.'Sub-region Code' -and -not $_.'Region Code' }
| ForEach-Object {
    [PSCustomObject]@{
        code    = $_.'M49 Code'
        name    = $_.'Country or Area'
        iso3166 = $_.'ISO-alpha3 Code'
        parent  = $_.'Global Code'
    }
}
| Sort-Object -Property code
| Get-Unique -AsString

$m49Codes += $methodology
| Where-Object { $_.'M49 Code' }
| ForEach-Object {
    [PSCustomObject]@{
        code    = $_.'M49 Code'
        name    = $_.'Country or Area'
        iso3166 = $_.'ISO-alpha3 Code'
        parent  = $_.'Intermediate Region Code'
    }
}
| Sort-Object -Property code
| Get-Unique -AsString

foreach ($m49Code in $m49Codes) {
    $m49Region = $regions | Where-Object { ($_.M49 -eq $m49Code.code) -or (($null -ne $m49Code.iso3166) -and ($_.ThreeLetterISORegionName -eq $m49Code.iso3166)) }
    if ($null -eq $m49Region) {
        $regions += [PSCustomObject]@{
            Name                         = $m49Code.code
            Parent                       = $null
            EnglishName                  = $m49Code.name
            TwoLetterISORegionName       = $null
            ThreeLetterISORegionName     = $null
            M49                          = $m49Code.code
            ThreeLetterWindowsRegionName = $null
            UnicodeFlag                  = $null
        }
    }
    elseif (($null -ne $m49Code.iso3166) -and ($m49Region.ThreeLetterISORegionName -eq $m49Code.iso3166)) {
        $m49Region.M49 = $m49Code.code
    }
    elseif ($m49Region.M49 -eq $m49Code.code) {
        $m49Region.EnglishName = $m49Code.name
    }
}
foreach ($m49Code in $m49Codes) {
    if ($null -ne $m49Code.parent) {
        $m49Region = $regions | Where-Object { ($_.M49 -eq $m49Code.code) }
        $m49ParentRegion = $regions | Where-Object { ($_.M49 -eq $m49Code.parent) }
        if (($null -ne $m49Region) -and ($null -ne $m49ParentRegion)) {
            $m49Region.Parent = $m49ParentRegion.Name
        }
    }
}

foreach ($region in $regions) {
    # edge cases
    if ($region.Name -eq 'TW') {
        $region.Parent = '030'
    }
    elseif ($region.Name -eq 'XK') {
        $region.Parent = '039'
    }
}

$regions = $regions | ConvertTo-Csv

$regions | Out-File Regions.csv
