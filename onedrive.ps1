$adminUPN="glenygc@svvtst.onmicrosoft.com"
$orgName="svvtst.onmicrosoft.com"
$userCredential = Get-Credential -UserName $adminUPN -Message "Type the password."
Connect-SPOService -Url https://svvtst-admin.sharepoint.com -Credential $userCredential

Get-Module -Name Microsoft.Online.SharePoint.PowerShell -ListAvailable | Select Name,Version
Install module
Install-Module -Name Microsoft.Online.SharePoint.PowerShell -Force



$orgName="svvtst"
Connect-SPOService -Url https://$orgName-admin.sharepoint.com


Set-SPOSite -Identity https://svvtst-my.sharepoint.com/personal/glenyg_svvtst_onmicrosoft_com -StorageQuotaReset

Get-SPODeletedSite -IncludeOnlyPersonalSite | FT url

Restore-SPODeletedSite -Identity https://svvtst-my.sharepoint.com/personal/testbruker1_svvtst_onmicrosoft_com

Set-SPOUser -Site https://svvtst-my.sharepoint.com/personal/testbruker1_svvtst_onmicrosoft_com -LoginName glenygc@svvtst.onmicrosoft.com -IsSiteCollectionAdmin $True

Remove-SPOSite -Identity https://svvtst-my.sharepoint.com/personal/testbruker1_svvtst_onmicrosoft_com