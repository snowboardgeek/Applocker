#Powershell for å signere filene i mappen C:\Data\Script
$cert = (dir cert:currentuser\my\ -CodeSigningCert)
$StiTilFileneSOmSkalSigneres = "C:\DATA\cmder_mini"
$Lagrinsplassforkatalogfilen = "C:\Data\catalog.cat"
 
New-FileCatalog -Path $StiTilFileneSOmSkalSigneres -CatalogVersion 2 -CatalogFilePath $Lagrinsplassforkatalogfilen
Set-AuthenticodeSignature $Lagrinsplassforkatalogfilen -Cert $cert -TimestampServer http://timestamp.comodoca.com/authenticode