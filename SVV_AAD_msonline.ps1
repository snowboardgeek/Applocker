Install-Module -Name MSonline

Connect-AzureAD -Confirm

Get-AzureADPolicy

Set-AzureADUser
get-azureaduser

Get-AzureADUser -SearchString "therese"

Get-AzureADUser -ObjectId f1b0a860-baaa-4074-b724-ea3004b08c84 | Select-object -Property *

5b0cf0df-5ac4-439d-bb20-2627f9d3a260

(Get-AzureADUser)[0] | Get-Member | Select-Object -Property othermail

set-AzureADUser -ObjectId bcf9aa8d-a878-4a46-941e-00e326c6e45a -OtherMails glen.mario.nygaard@vegvesen.no

Disconnect-AzureAD


Get-MsolDevice -all | select-object -Property Enabled, DeviceId, DisplayName, DeviceTrustType, Approxi
mateLastLogonTimestamp | export-csv devicelist-summary.csv

Get-AzureADDevice -All | select-object -Property

ApproximateLastLogonTimestamp
Get-MsolDevice -All | Select-Object -Property Enabled, deviceID, Displayname, DeviceTrustType, ApproximateLastLogonTimestamp  | export-csv -Path C:\data\Azure_devicelistSVV.csv

$dt = [datetime]’2019/03/01’
Get-MsolDevice -all -LogonTimeBefore $dt | select-object -Property Enabled, DeviceId, DisplayName, DeviceTrustType, ApproximateLastLogonTimestamp | export-csv -Path C:\data\Azure_devicelistSVV_olderthanMars2019.csv

Disconnect-AzureAD