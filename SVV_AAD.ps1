Install-Module -Name AzureADPreview 

Connect-AzureAD -Confirm

Get-AzureADPolicy

Set-AzureADUser
get-azureaduser

Get-AzureADUser -SearchString "john-vidar.stene"

Get-AzureADUser -ObjectId e7371bd9-823b-4121-a355-9cd385f8b551 | Select-object -Property *

5b0cf0df-5ac4-439d-bb20-2627f9d3a260

(Get-AzureADUser)[0] | Get-Member | Select-Object -Property othermail

set-AzureADUser -ObjectId bcf9aa8d-a878-4a46-941e-00e326c6e45a -OtherMails glen.mario.nygaard@vegvesen.no
set-AzureADUser -ObjectId a206dec1-7616-4edb-bf53-04300adce4d5 -OtherMails ella.hansen@vegvesen.no

e7371bd9-823b-4121-a355-9cd385f8b551

Disconnect-AzureAD

