Invoke-Expression (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/sharepoint/PnP-PowerShell/master/Samples/Modules.Install/Install-SharePointPnPPowerShell.ps1')

Install-Module SharePointPnPPowerShellOnline -AllowClobber

Connect-PnPOnline -Url "https://vegvesen.sharepoint.com" -UseWebLogin


Install-Module SharePointPnPPowerShellOnline -AllowClobbe