<#

.SYNOPSIS
To fix a number of Office 365 Update issues.

.DESCRIPTION
First the script will add OfficeC2RCom as COM+ application and then refresh the update channel for Office 365.

.EXAMPLES

C:\PS> Office365UpdateScript.ps1 -Channel "Monthly"

.NOTES
Channel CDNBase URL:
    •	Monthly Channel 
        http://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60

    •	Semi-Annual Channel 
        http://officecdn.microsoft.com/pr/7ffbc6bf-bc32-4f92-8982-f9dd17fd3114

    •	Monthly Channel (Targeted)
        http://officecdn.microsoft.com/pr/64256afe-f5d9-4f86-8936-8840a6a4f5be

    •	Semi-Annual Channel (Targeted) 
        http://officecdn.microsoft.com/pr/b8f9b850-328d-4355-9145-c59439a0c4cf

.LINK
https://msdn.microsoft.com/en-us/library/office/mt608768.aspx
https://www.reddit.com/r/SCCM/comments/7jsyby/office_365_updates_failing_0x87d0024a/
https://getadmx.com/?Category=Office2016&Policy=office16.Office.Microsoft.Policies.Windows::L_UpdateBranch

#>


param(
    [Parameter()]
    [ValidateSet("MonthlyTargeted","Monthly","SemiAnnualTargeted","SemiAnnual")]
    [string]$Channel
    )


Function ChannelChange ($Channel) {

    If ($channel -eq "MonthlyTargeted"){
    $CDNBaseUrl = "64256afe-f5d9-4f86-8936-8840a6a4f5be"
    $UpdateBranch = "FirstReleaseCurrent "
        }elseif($channel -eq "Monthly"){
        $CDNBaseUrl = "492350f6-3a01-4f97-b9c0-c7c6ddf67d60"
        $UpdateBranch = "Current"
            }elseif($channel -eq "SemiAnnualTargeted"){
            $CDNBaseUrl = "b8f9b850-328d-4355-9145-c59439a0c4cf"
            $UpdateBranch = "FirstReleaseDeferred"
                }elseif($channel -eq "SemiAnnual"){
                $CDNBaseUrl = "7ffbc6bf-bc32-4f92-8982-f9dd17fd3114"
                $UpdateBranch = " Deferred"
                }



new-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -Name CDNBaseUrl -Value  "http://officecdn.microsoft.com/pr/$CNDBaseUrl" -PropertyType String -Force
new-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Common\OfficeUpdate\" -Name "updatebranch" -Value $UpdateBranch  -force
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -Name "UpdateUrl" -Force
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -Name "UpdateUrl" -Force
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -Name "UpdateToVersion" -Force
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Updates" -Name "UpdateToVersion" -Force
Start-Process -FilePath "$env:CommonProgramFiles\microsoft shared\ClickToRun\OfficeC2RClient.exe" -ArgumentList "/update user" -wait

}

function OfficeC2Rcom {
#Remove the COM+ Application which was hosting the UpdateNotify.Object
Write-Host "Remove the OfficeC2RCom COM+ App if exists"
$comCatalog = New-Object -ComObject COMAdmin.COMAdminCatalog
$appColl = $comCatalog.GetCollection("Applications")
$appColl.Populate()

foreach($app in $appColl)
{
    if ($app.Name -eq "OfficeC2RCom")
    {
      $appColl.Remove($index)
      $appColl.SaveChanges()
    }
    $index++
}

# Create a COM+ application to host UpdateNotify.Object
$comAdmin = New-Object -comobject COMAdmin.COMAdminCatalog
$apps = $comAdmin.GetCollection("Applications")
$apps.Populate();


$newComPackageName = "OfficeC2RCom"

$app = $apps | Where-Object {$_.Name -eq $newComPackageName}

if ($app) 
{
    # OfficeC2RCom app already exists. Output some info about it
    Write-Host ""
    $appname = $app.Value("Name")
    "This COM+ Application already exists : $appname"
    Write-Host ""

    "ID: " +  $app.Value("ID")
    "Identity: " +  $app.Value("Identity")
    "ApplicationDirectory: " + $app.Value("ApplicationDirectory")
    "ConcurrentApps:" + $app.Value("ConcurrentApps")
    "RecycleCallLimit:" + $app.Value("RecycleCallLimit")
    "Activation:" + $app.Value("Activation")
    "ApplicationAccessChecksEnabled:" + $app.Value("ApplicationAccessChecksEnabled")
    Write-Host ""
}
Else
{
    # OfficeC2RCom app doesn't exist, creat it

    # Add the App
    Write-Host "Adding OfficeC2RCom COM+ Application..."

    Try
    {
      $app = $apps.Add()
      $app.Value("Name") = $newComPackageName
      $app.Value("Identity") = "NT AUTHORITY\LocalService"
      $app.Value("ApplicationAccessChecksEnabled") = 1
      $app.Value("ID") = "{F6B836D9-AF6A-4D05-9A19-E906A0F34770}"
      $saveChangesResult = $apps.SaveChanges()
      "Results of the Apps SaveChanges operation : $saveChangesResult"

      $appid = $app.Value("ID")

      # Adding roles
      Write-Host "Adding Administrator role to $newComPackageName"
      $roles = $apps.GetCollection("Roles", $app.Key)
      $roles.Populate()
      $role = $roles.Add()
      $role.Value("Name") = "Administrator"
      $saveChangesResult = $roles.SaveChanges()
      "Results of the Roles SaveChanges operation : $saveChangesResult"

      # Get the localized string of the Builtin\Administrators
      $id = [System.Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid
      $Account = New-Object System.Security.Principal.SecurityIdentifier($id, $null)
      $localizedAdministrators = $Account.Translate([System.Security.Principal.NTAccount]).Value
      "Results of the localized administrators string : $localizedAdministrators"
      # Adding BUILTIN\Administrators to the Administrator Role
      $users = $roles.GetCollection("UsersInRole", $role.Key)
      $users.Populate()
      $user = $users.Add()
      $user.Value("User") = $localizedAdministrators
      $saveChangesResult = $users.SaveChanges()
      "Results of the Users SaveChanges operation : $saveChangesResult"
    }
    catch
    {
      Write-Host "Failed to add OfficeC2RCom as COM+ application." -ForegroundColor White -BackgroundColor Red
      exit
    }

    Write-Host "Successfully added COM+ application: $newComPackageName, id: $appid" -ForegroundColor Blue -BackgroundColor Green
}

# Adding the UpdateNotify.Object as the component of OfficeC2RCom
$comps = $apps.GetCollection("Components", $app.Key)
$comps.Populate()
$newCompName = "UpdateNotify.Object.1"

$comp = $comps | Where-Object {$_.Name -eq "UpdateNotify.Object.1"}

if ($comp)
{
  "The $newCompName already exists!"
}
Else
{
  Try
  {
    $comAdmin.ImportComponent($newComPackageName, $NewCompName)
  }
  catch
  {
      Write-Host "Failed to add $newCompName to $newComPackageName" -ForegroundColor White -BackgroundColor Red
      exit
  }
  Write-Host "Successfully added $newCompName to $newComPackageName" -ForegroundColor Blue -BackgroundColor Green
} 
}

#Main Script
OfficeC2Rcom
ChannelChange $Channel



