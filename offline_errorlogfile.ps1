<#
.SYNOPSIS
	Checks from event logs for 1002 ID with message "Background Synchronization executed successfully." this proves sync is working and if cannot be found then creates log file of recent errors.

.DESCRIPTION
    This was created to monitor if offline files sync is not working on local machine, most usually breaks during OS patches or some other weird issue.
	
.PARAMETER install
	Typing "Offline_ErrorLogFile.ps1 -install" will create a local Task Scheduler job under SYSTEM.  Job runs weekly Tuesday, Friday.  

.EXAMPLE
	.\Offline_ErrorLogFile.ps1 -i
	.\Offline_ErrorLogFile.ps1 -install
    .\Offline_ErrorLogFile.ps1 -u
    .\Offline_ErrorLogFile.ps1 -unistall
	
.NOTES  
	File Name		:	Offline_ErrorLogFile.ps1
	Author			:	Joni Mattila
	Version			:	1.0
	Modified		:	30.08.2017
#>

[CmdletBinding()]

param (
	[Parameter(Mandatory=$False, Position=1, ValueFromPipeline=$false, HelpMessage='Use -install -i parameter to add script to Windows Task Scheduler on local machine')]
	[Alias("i")]
	[switch]$install,

	[Parameter(Mandatory=$False, Position=3, ValueFromPipeline=$false, HelpMessage='Use -uninstall -u parameter to remove Windows Task Scheduler job')]
	[Alias("u")]
	[switch]$uninstall

)

## Set the script execution policy for this process
Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}

Function Installer() {
	# Add to Task Scheduler
	Write-Output "  Installing to Task Scheduler..."
	$user = $ENV:USERDOMAIN + "\"+$ENV:USERNAME
	Write-Output "  Current User: $user"
# Create local on current machine
		$machines += "localhost"
	# Task Scheduler command
    new-item -type directory -path "${env:ProgramFiles}\Company\OfflineError" -Force  -ErrorAction SilentlyContinue | Out-Null
    Write-Host " Created folder in Program Files under Company\OfflineError  [OK]" -Fore Green
    Copy-Item Offline_Errorlogfile.ps1 -Destination	"${env:ProgramFiles}\Company\OfflineError"
    Write-Host " Copied powershell script  [OK]" -Fore Green

	if ($uninstall) {

	}
	$machines | ForEach-Object {
		if ($uninstall) {
			# Delete task
			Write-Output "SCHTASKS DELETE on $_"
			schtasks /s $_ /delete /tn "Offline_ErrorLogFile" /f
			Write-Host "Task deleted  [OK]" -Fore Green
            Remove-Item  -Path "${env:ProgramFiles}\Company\OfflineError\Offline_Errorlogfile.ps1" -ErrorAction SilentlyContinue
            Write-Host "Script deleted from Program Files under Company\OfflineError  [OK]" -Fore Green
		} else {
			# Create task
			schtasks /create /tn "Offline_ErrorLogFile" /xml "Offline_ErrorLogFile.xml" /ru "NT AUTHORITY\SYSTEM" /f
			Write-Host "Task Created  [OK]" -Fore Green
		}
	}
}

Function Offline() {
$ExportPath = "C:\windows\temp\" + "OfflineErrorlog.csv"
$time = (Get-Date) – (New-TimeSpan -Day 1)
$events = Get-WinEvent -ErrorAction SilentlyContinue -MaxEvents 1 @{logname= "Microsoft-Windows-OfflineFiles/Operational"; level=4; starttime=$time; id=1002; providername=’Microsoft-Windows-OfflineFiles’ }|
where-object { $_.message -like "Background Synchronization executed successfully."}
if($events -ne $null)
{
Write-Host "Synchronization works [OK]" -Fore Green
if (Test-Path "C:\windows\temp\OfflineErrorlog.csv") 
## Delete old errorlog from C:\windows\temp since succesful sync is found from logs.
{Remove-Item  -Path "C:\windows\temp\OfflineErrorlog.csv" -ErrorAction SilentlyContinue
Write-Host "Deleted errorlog from C:\windows\temp [OK]" -Fore Green}
}
else
{
Write-Host "Synchronization is broken [ERROR]" -Fore Cyan
$errorevents = Get-WinEvent -ErrorAction SilentlyContinue -MaxEvents 100 @{logname= "Microsoft-Windows-OfflineFiles/Operational"; starttime=$time; providername=’Microsoft-Windows-OfflineFiles’ }|
Select-Object @{ e={$_.MachineName};l='Server' },@{ e={$_.LogName}; l='LogName' },@{ e={$_.ID}; l='EventID' }, @{ e={$_.LevelDisplayName}; l='Level' },@{ e={$_.ProviderName}; l='Source' }, @{ e={$_.message}; l='Message' },@{ e={$_.TimeCreated}; l='Created' }| Export-Csv -Path $ExportPath -NoTypeInformation -ErrorAction Stop
}
}
# Install command
$cmdpath = $MyInvocation.MyCommand.Path
		if ($install -or $uninstall) {
            Installer			
		}
		if ($uninstall) {
			break
		}
#Invoke function Offline
Offline