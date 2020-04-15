$rootPath = "\\?\O:\Programdata\Plania\2 Sør\Aust-Agder\Tunneler\3.Riksveg"
$csvFilename = "c:\data\Tunnelfiler-AustAgder.csv"   #Output will be written to csv file

Get-ChildItem -LiteralPath $rootPath -rec | Where-object {!$_.psIsContainer -eq $true -and $_.FullName -like “*tunnel*”} | Select-Object directoryname, name, LastWriteTime, length | Export-Csv -Path $csvFilename -Encoding ascii -NoTypeInformation