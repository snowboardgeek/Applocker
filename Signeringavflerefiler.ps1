#SCRIPT SETTINGS
 $DirectoryToSign = 'C:\DATA\applocker\Matrix Rs'
 $SkipCatalogFile = $True #Needed only if you have to sign files that do not support Set-Authenticode signature. The catalog file also has to be installed on each computer needing to run the signed code.
 　
$cert = (dir cert:currentuser\my\ -CodeSigningCert) | Out-GridView -PassThru 
  #Exit if no certificate
if
 ($cert){} else {
   
"No certificate chosen, exiting...."
   
exit
 }
Set-Location  $DirectoryToSign
if ($SkipCatalogFile -eq $true) {
  "Oppretter katalogfil $KatlogFilNavn under $DirectoryToSign"
  #Lager katalogfil i tilfelle det er filer som ikke kan signeres direkte
  Remove-Item "$DirectoryToSign\$CatalogFileName" -Force -ErrorAction Ignore
  New-FileCatalog -CatalogVersion 2 -CatalogFilePath "$DirectoryToSign\$CatalogFileName" -Path $DirectoryToSign
  #Signerer katalog fil
  "Signerer katalogfil ..."
  "$DirectoryToSign\$CatalogFileName" | Set-AuthenticodeSignature -Certificate $Cert -TimestampServer http://timestamp.comodoca.com/authenticode
}
#Signerer dll filer direkte
"Signerer DLL filer..."
Get-ChildItem -Path $DirectoryToSign -recurse -Filter "*.dll" | Get-AuthenticodeSignature | Where {$_.Status -ne "Valid"} | ForEach {$_.Path} | Set-AuthenticodeSignature -Certificate $Cert -TimestampServer http://timestamp.comodoca.com/authenticode -ErrorAction Continue | ft
#Signerer exe filer direkte
"Signerer EXE filer..."
Get-ChildItem $DirectoryToSign -Recurse -Filter "*.exe" | Get-AuthenticodeSignature | Where {$_.Status -ne "Valid"} | ForEach {$_.Path} | Set-AuthenticodeSignature -Certificate $Cert -TimestampServer http://timestamp.comodoca.com/authenticode -ErrorAction Continue | ft
#Signerer ps1 filer direkte
"Signerer PowerShell filer..."
Get-ChildItem $DirectoryToSign -Recurse -Filter "*.ps1" | Get-AuthenticodeSignature | Where {$_.Status -ne "Valid"} | ForEach {$_.Path} | Set-AuthenticodeSignature -Certificate $Cert -TimestampServer http://timestamp.comodoca.com/authenticode -ErrorAction Continue | ft
"OBS: Sjekk at det ikke kom noen feilmeldinger.."