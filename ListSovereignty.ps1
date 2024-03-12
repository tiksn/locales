$sovereigntyTable = Read-HTMLTable -Uri 'https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes' -TableIndex 0
$independenceTable = Read-HTMLTable -Uri 'https://en.wikipedia.org/wiki/ISO_3166-1' -TableIndex 1

$independenceList = $independenceTable
| ForEach-Object {
    [PSCustomObject]@{
        Name            = $_.(($_ | Get-Member | Where-Object { $_.Name.Contains('English short name') }).Name)
        TwoLetterCode   = $_.'Alpha-2 code'
        ThreeLetterCode = $_.'Alpha-3 code'
        Independent     = ($_.Independent -eq 'Yes') -or ($_.'Alpha-2 code' -eq 'TW') -or ($_.'Alpha-2 code' -eq 'PS')
        Sovereignty     = $null
    }
}
| Where-Object {
    $_.Name -ne 'Antarctica'
}

$sovereigntyList = $sovereigntyTable
| ForEach-Object {
    [PSCustomObject]@{
        Name            = $_.(($_ | Get-Member | Where-Object { $_.Name.Contains('ISO 3166[1]') }).Name)
        TwoLetterCode   = $_.(($_ | Get-Member | Where-Object { $_.Name.Contains('ISO 3166-1[2]') -and $_.Name.Contains('A-2') }).Name)
        ThreeLetterCode = $_.(($_ | Get-Member | Where-Object { $_.Name.Contains('ISO 3166-1[2]') -and $_.Name.Contains('A-3') }).Name)
        Sovereignty     = $_.(($_ | Get-Member | Where-Object { $_.Name.Contains('Sovereignty') }).Name)
    }
}
| Where-Object {
    $_.TwoLetterCode.Length -eq 2
}
| Where-Object {
    $_.Sovereignty -ne 'Antarctic Treaty'
}
| ForEach-Object {
    $independent = ($_.Sovereignty -eq 'UN member') -or ($_.Sovereignty -eq 'UN observer') -or ($_.TwoLetterCode -eq 'TW')
    $sovereignty = if (($_.Sovereignty -eq 'UN member') -or ($_.Sovereignty -eq 'UN observer')) {
        $_.TwoLetterCode
    }
    elseif ($_.Sovereignty -eq 'Finland') {
        'FI'
    }
    elseif ($_.Sovereignty -eq 'United States') {
        'US'
    }
    elseif ($_.Sovereignty -eq 'United Kingdom') {
        'GB'
    }
    elseif ($_.Sovereignty -eq 'Netherlands') {
        'NL'
    }
    elseif ($_.Sovereignty -eq 'Norway') {
        'NO'
    }
    elseif ($_.Sovereignty -eq 'Australia') {
        'AU'
    }
    elseif ($_.Sovereignty -eq 'New Zealand') {
        'NZ'
    }
    elseif ($_.Sovereignty -eq 'Denmark') {
        'DK'
    }
    elseif ($_.Sovereignty -eq 'France') {
        'FR'
    }
    elseif ($_.Sovereignty -eq 'British Crown') {
        'GB'
    }
    elseif ($_.Sovereignty -eq 'China') {
        'CN'
    }
    elseif ($_.TwoLetterCode -eq 'TW') {
        'TW'
    }
    elseif ($_.TwoLetterCode -eq 'EH') {
        'MA'
    }
    else {
        throw $_
    }
    [PSCustomObject]@{
        Name            = $_.Name
        TwoLetterCode   = $_.TwoLetterCode
        ThreeLetterCode = $_.ThreeLetterCode
        Independent     = $independent
        Sovereignty     = $sovereignty
    }
}

$combined = New-Object System.Collections.ArrayList
$combined.AddRange($independenceList)
$combined.AddRange($sovereigntyList)
$combined.AddRange(@(
        [PSCustomObject]@{
            Name            = 'Kosovo'
            TwoLetterCode   = 'XK'
            ThreeLetterCode = ''
            Independent     = $true
            Sovereignty     = 'XK'
        }))

$combined
| Group-Object -Property TwoLetterCode
| ForEach-Object {
    if ($_.Count -eq 1) {
        $_.Group[0]
    }
    else {
        if (($_.Group | Select-Object -ExpandProperty Independent | Select-Object -Unique).Length -ne 1) {
            throw 'Independent value should be the same for entries per country code'
        }

        [array]$sovereignties = $_.Group | Where-Object { $_.Sovereignty -ne $null }
        if ($sovereignties.Length -ne 1) {
            throw 'There should be only 1 Sovereignty record'
        }
        $sovereignties[0]
    }
}
| ForEach-Object {
    if ($_.Independent -and ($_.TwoLetterCode -ne $_.Sovereignty)) {
        throw 'Independent countries Sovereignty code must be the same as TwoLetterCode'
    }
    $_
}
| Sort-Object -Property TwoLetterCode
