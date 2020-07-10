$cultures = [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::AllCultures)
$cultures = $cultures | ForEach-Object {
    [PSCustomObject]@{
        Name                           = $_.Name
        # DisplayName                    = $_.DisplayName
        EnglishName                    = $_.EnglishName
        NativeName                     = $_.NativeName
        Parent                         = $_.Parent
        IetfLanguageTag                = $_.IetfLanguageTag
        TwoLetterISOLanguageName       = $_.TwoLetterISOLanguageName
        ThreeLetterISOLanguageName     = $_.ThreeLetterISOLanguageName
        ThreeLetterWindowsLanguageName = $_.ThreeLetterWindowsLanguageName
        IsNeutralCulture               = [int]$_.IsNeutralCulture
    }
}

$cultures = $cultures | ConvertTo-Csv

$cultures | Out-File cultures.csv
