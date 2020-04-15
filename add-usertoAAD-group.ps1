Install-Module -Name AzureAD

Connect-AzureAD
 
 
 $users = import-csv C:\data\Anslag_tilAAD.csv
 
foreach ($user in $users){
 
$upn = get-azureaduser -objectid ($user.UserPrincipalName + "@vegvesen.no")
$obid = $upn.ObjectId
#$obid
 
#ADd user tyo group change ObjectID to the group that shoud have the users
Add-AzureADGroupMember -ObjectId 2b79babf-819e-4691-a823-f95f2ee5e9ab -RefObjectId $upn.objectid
 
Write-Host "adding user "$upn.UserPrincipalName" with object id $obid"  -ForegroundColor Green
}



Get-AzureADGroupMember -ObjectId 2b79babf-819e-4691-a823-f95f2ee5e9ab -Top 10000 | Out-File -FilePath c:\data\usersingroup.csv

disconnect-AzureAD