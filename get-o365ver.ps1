$O365CurrentVer = ""
$O365CurrentCdn = "" 
$O365CurrentPol = ""
$O365CurrentVer = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -ErrorAction SilentlyContinue).VersionToReport 
$O365CurrentCdn = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -ErrorAction SilentlyContinue).CDNBaseUrl
$O365CurrentPol = (Get-ItemProperty -Path "HKLM:\SOFTWARE\policies\microsoft\office\16.0\common\officeupdate" -ErrorAction SilentlyContinue).updatebranch
if ($O365CurrentVer.Length -eq 0) {
    Write-Host "Office 365 (C2R) is not installed on this PC."
}
else
{
    Write-Host "Office 365 (C2R) Current Version: "$O365CurrentVer
    switch ($O365CurrentCdn) {
        "http://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60" {$O365CurrentCdn = "Monthly Channel"}
        "http://officecdn.microsoft.com/pr/7ffbc6bf-bc32-4f92-8982-f9dd17fd3114" {$O365CurrentCdn = "Semi-Annual Channel"}
        "http://officecdn.microsoft.com/pr/b8f9b850-328d-4355-9145-c59439a0c4cf" {$O365CurrentCdn = "Semi-Annual Channel (Targeted)"}
    }
    Write-Host "Office 365 Update Channel (Local Setting): "$O365CurrentCdn
    if ($O365CurrentPol.length -eq 0) {
        $O365CurrentPol = "None"
    } else {
        switch ($O365CurrentPol) {
            "Current" {$O365CurrentPol = "Monthly Channel"}
            "Deferred" {$O365CurrentPol = "Semi-Annual Channel"}
            "FirstReleaseDeferred" {$O365CurrentPol = "Semi-Annual Channel (Targeted)l"}
        }
    }
    Write-Host "Office 365 Update Channel (Policy Setting): "$O365CurrentPol
}