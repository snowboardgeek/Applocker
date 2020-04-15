Get-Module -Name Microsoft.Online.SharePoint.PowerShell -ListAvailable | Select Name,Version

Install-Module -Name Microsoft.Online.SharePoint.PowerShell


Connect-SPOService -Url https://svvtst-admin.sharepoint.com -credential glenygc@svvtst.onmicrosoft.com

Connect-PnPOnline -Url https://svvtst-admin.sharepoint.com

$orgName="svvtst"
Connect-SPOService -Url https://$orgName-admin.sharepoint.com


##############################################################################

$loginname = "glenygc@svvtst.onmicrosoft.com" # your login name that your going to run the script with

$AllSites = get-sposite -Limit all
$myArray = [System.Collections.ArrayList]@()

foreach ($url in $AllSites.url)
{

#Get all the site collection admins
$myarray = Get-SPOUser -Site $url | where {$_.IsSiteAdmin}

#print the results
$myarray |
select DisplayName ,LoginName, Groups, @{Name='URL';Expression={[string]$url}}
}

#############################################################

$AllSites = get-sposite -limit all
$myArray = [System.Collections.ArrayList]@()


foreach ($url in $AllSites.url)
{
#Set the site collection admin
Set-SPOUser -Site $url -LoginName $loginname -IsSiteCollectionAdmin $true |out-null

#Get all the site collection admins in an array
$myarray = Get-SPOUser -Site $url | where {$_.IsSiteAdmin}

#Remove your account from the array
$data = $myarray | ? {$_.LoginName -ne $loginname}

#Remove yourself as site collection admin
Set-SPOUser -Site $url -LoginName $loginname -IsSiteCollectionAdmin $false |out-null -ErrorAction silentlycontinue


#print the results
$data |
select DisplayName ,LoginName, Groups, @{Name='URL';Expression={[string]$url}}
}
########################################################################

select DisplayName ,LoginName, Groups, @{Name='URL';Expression={[string]$url}} | Export-Csv -path "C:folderfilename.csv" -append

#########################################################################

$loginname = ""
$AllSites = Import-Csv "C:folderfilename.csv" #grab the CSV


$myArray = [System.Collections.ArrayList]@()




foreach ($url in $AllSites.url)
{
#set the site collection admin
Set-SPOUser -Site $url -LoginName $loginname -IsSiteCollectionAdmin $true |out-null
#write-host "Getting site collection admins for"$v -ForegroundColor green

#get all the site collection admins
$myarray = Get-SPOUser -Site $url | where {$_.IsSiteAdmin}

#remove yourself from the array
$data = $myarray | ? {$_.LoginName -ne $loginname}

#remove yourself as site collection admin
Set-SPOUser -Site $url -LoginName $loginname -IsSiteCollectionAdmin $false |out-null -ErrorAction silentlycontinue


$data |
select DisplayName ,LoginName, Groups, @{Name='URL';Expression={[string]$url}} | Export-Csv -path "C:folderfilename.csv" -append
}



##Json join a hubsite

{
    "verb": "joinHubSite",
    "hubSiteId": "e337cc17-b355-45d2-8dd4-e056f1bcf6f6"
}