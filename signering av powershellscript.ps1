$cert = (dir cert:currentuser\my\ -CodeSigningCert)
Set-AuthenticodeSignature C:\data\applocker\TestRunExcel-Signert.ps1 $cert -TimestampServer http://timestamp.comodoca.com/authenticode
Exempel: Set-AuthenticodeSignature c:\DATA\testscript.ps1 $cert -TimestampServer http://timestamp.comodoca.com/authenticode