###############Add site collection administrators###################

##Add Site Collection Administrator in Modern / Group Connected SharePoint Online Sites:
##In group connected modern team sites, "Site collection Administrators" link in site settings is hidden. The Office 365 Group Owner is configured as the site collection administrator, by default. So you can add any user to owners group of the Office 365 group in order to make them site collection administrator or use the direct link and add additional site collection admins. 

##Anyway, In SharePoint Online, site collection administrators to be added on a site collection by site collection basis, as there is no web application level users policies can be set from Central Administration as we do in SharePoint on-premises. So, the solution is: Using PowerShell to add site collection administrator in SharePoint online!

##PowerShell Script to Add Site Collection Administrator in SharePoint Online:
##Here is the PowerShell for SharePoint online to add site collection administrator 

#Variables for processing
$AdminURL = "https://svvtst-admin.sharepoint.com/"
$AdminName = "glenygc@crescent.onmicrosoft.com"
$SiteCollURL = "https://svvtst.sharepoint.com/sites/20190903glen"
$SiteCollectionAdmin = "glenygc@svvtst.onmicrosoft.com"
 
#User Names Password to connect 
#$SecurePWD = read-host -assecurestring "Enter Password for $AdminName" 
$SecurePWD = ConvertTo-SecureString "Password1" –asplaintext –force  
$Credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $AdminName, $SecurePWD
  
#Connect to SharePoint Online
Connect-SPOService -url $AdminURL -credential $Credential
 
#Add Site collection Admin
Set-SPOUser -site $SiteCollURL -LoginName $SiteCollectionAdmin -IsSiteCollectionAdmin $True
##This PowerShell also works when you want to add group site collection administrator in SharePoint Online. 

##Add Site collection Admin to All SharePoint Online Sites using PowerShell:
##SharePoint online PowerShell to add site collection administrator for all site collections.

#Variables for processing
$AdminURL = "https://Crescent-admin.sharepoint.com/"
$AdminName = "SPAdmin@Crescent.com"
  
#User Names Password to connect 
$Password = Read-host -assecurestring "Enter Password for $AdminName"
$Credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $AdminName, $Password
 
#Connect to SharePoint Online
Connect-SPOService -url $AdminURL -credential $Credential
 
$Sites = Get-SPOSite -Limit ALL
 
Foreach ($Site in $Sites)
{
    Write-host "Adding Site Collection Admin for:"$Site.URL
    Set-SPOUser -site $Site -LoginName $AdminName -IsSiteCollectionAdmin $True
}
##To Remove a Site Collection Admin, use Set-SPOUser cmdlet with -IsSiteCollectionAdmin $false parameter! Here is how: Remove Site Collection Administrator in SharePoint Online with PowerShell

##Change Primary Site Collection Administrator using PowerShell:
##SharePoint Online PowerShell to set site collection administrator 

#Variables for processing
$AdminURL = "https://crescent-admin.sharepoint.com/"
$AdminName = "salaudeen@crescent.onmicrosoft.com"
$SiteCollURL = "https://crescent.sharepoint.com/sites/Sales"
$NewSiteAdmin = "mark@crescent.onmicrosoft.com"
 
#User Names Password to connect 
$SecurePWD = ConvertTo-SecureString "Password1" –asplaintext –force  
$Credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $AdminName, $SecurePWD
  
#Connect to SharePoint Online
Connect-SPOService -url $AdminURL -credential $Credential
 
#Change Site Collection Primary Admin
Set-SPOSite -Identity $SiteCollURL -Owner $NewSiteAdmin -NoWait

##Add Site collection Administrator to Group/Modern Sites
##SharePoint modern sites are not listed under site collections (or even with SharePoint PowerShell module!). Here is the script to use in "SharePoint Online Management Shell" to add site collection admins to all sites including Modern Team sites.

#Variables for processing
$AdminURL = "https://crescent-admin.sharepoint.com/"
$AdminName="SPAdmin@crescent.com"
 
#Connect to SharePoint Online
Connect-SPOService -url $AdminURL -credential (Get-Credential)
 
#Get All Site Collections
$Sites = Get-SPOSite -Limit ALL
 
#Loop through each site and add site collection admin
Foreach ($Site in $Sites)
{
    Write-host "Adding Site Collection Admin for:"$Site.URL
    Set-SPOUser -site $Site.Url -LoginName $AdminName -IsSiteCollectionAdmin $True
}

##You can apply filter on site collections to get all site collections of specific type. E.g. To get all communication sites, use: Get-SPOSite -Template SITEPAGEPUBLISHING#0 

##Add Site Collection Administrator using PowerShell CSOM:
##Other than SharePoint Online Management shell, we can also use PowerShell CSOM method to add a user to site collection administrator group. Here is how:


#Load SharePoint CSOM Assemblies
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
  
#Variables for Processing
$SiteURL = "https://crescent.sharepoint.com/Sites/marketing"
$UserAccount="i:0#.f|membership|Salaudeen@crescent.com"
 
#Setup Credentials to connect
$Cred = Get-Credential
$Cred = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Cred.UserName,$Cred.Password)
 
#Setup the context
$Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
$Ctx.Credentials = $Cred
 
$User = $Ctx.Web.EnsureUser($UserAccount)
$User.IsSiteAdmin = $True
$User.Update()
$Ctx.ExecuteQuery()

##PnP PowerShell to Add Site Collection Administrator in SharePoint Online
##Here is how to add user to site collection administrator using PowerShell 


#Set Variables
$orgName="svvtst"
$SiteURL = "https://svvtst.sharepoint.com/sites/20190903glen"

#Connect to PNP Online
Connect-PnPOnline -Url $SiteURL -Credentials (Get-Credential)
 
#Get the List Item

Add-PnPSiteCollectionAdmin -Owners "Salaudeen@crescent.com"

##Similarly, to add more than one site collection admin, use: 

Add-PnPSiteCollectionAdmin -Owners "Salaudeen@crescent.com", "Charles@crescent.com"


#Read more: https://www.sharepointdiary.com/2015/08/sharepoint-online-add-site-collection-administrator-using-powershell.html#ixzz5yUuyf5jT