<#
.SYNOPSIS
    This script creates or modifies a local AppAssoc.xml file, used to for file type associations with group policy

.PARAMETER Logfile
    Can be empty (no log), a path to a file or the expression "<default>". The default expression uses the evironment's temp directory.

.PARAMETER Path
    The path to the AppAssoc.xml file. If file does not exist and -CreateIfNotExists is specified, the file is created first.

.PARAMETER Extension
    The file extension, the application should handle.

.PARAMETER ProgId
    The program ID, indicating the application, which should be associated with the specified file type. 

.PARAMETER AppName
    Specifies the name of the application, which is used to open the file type.

.NOTES
    Author:   Helmut Wagensonner, Microsoft
    Creation: 13/03/18

.EXAMPLE
    .\Modify-AppAssocXml.ps1 -Path "C:\Users\Public\Microsoft\Windows\AppAssoc.xml" -Logfile "<default>" -Extension ".avi" -AppId "VLC.avi" -AppName "VLC Media Player" -CreateIfNotExists
#>

# This Sample Code is provided for the purpose of illustration only and is not intended to be used 
# in a production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" 
# WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED 
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We grant You a nonexclusive, 
# royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code 
# form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to 
# market Your software product in which the Sample Code is embedded; (ii) to include a valid copyright 
# notice on Your software product in which the Sample Code is embedded; and (iii) to indemnify, hold 
# harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorney 
# fees, that arise or result from the use or distribution of the Sample Code.

# This sample script is not supported under any Microsoft standard support program or service. 
# The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims 
# all implied warranties including, without limitation, any implied warranties of merchantability 
# or of fitness for a particular purpose. The entire risk arising out of the use or performance of 
# the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, 
# or anyone else involved in the creation, production, or delivery of the scripts be liable for any 
# damages whatsoever (including, without limitation, damages for loss of business profits, business 
# interruption, loss of business information, or other pecuniary loss) arising out of the use of or 
# inability to use the sample scripts or documentation, even if Microsoft has been advised of the 
# possibility of such damages 

param
(
	[Parameter(Mandatory = $true)]
	[string] $Path, 				#= ".\AppAssoc.xml",
	
	[Parameter(Mandatory = $true)]
	[string] $Extension, 			#= ".xAy,.XQZ,xqw",
	
	[Parameter(Mandatory = $true)]
	[string] $ProgId, 				#= "Applications\XAYHandler",
	
	[Parameter(Mandatory = $true)]
	[string] $AppName, 				#= "XAY Event Handler 1.0",

	[string] $Logfile = "<default>",

	[switch] $CreateIfNotExists = $false
)

$psScriptRoot = (Get-Item $MyInvocation.MyCommand.Definition).DirectoryName
$scriptBaseName = (Get-Item $MyInvocation.MyCommand.Definition).BaseName
$tempDirectory = $env:TEMP
$startDate = Get-Date -Format "yyyy-MM-dd HH-mm-ss"
if ($LogFile -eq "<default>")
{
	$LogFile = "$($tempDirectory)\$($scriptBaseName).LOG"
}

Function Write-Log([string]$logtext, [string]$logerr, [bool]$writeToHost = $true, [bool]$writeToFile = $true, [bool]$writeToEventLog = $false)
{
	$currentTime = Get-Date -Format "HH:mm:ss.fff"

	if ($writeToHost)
	{
		switch ($logerr)
		{
			"E" {write-host "$($currentTime) --> $($logtext)" -ForegroundColor "Black" -BackgroundColor "Red"}
			"W" {write-host "$($currentTime) --> $($logtext)" -ForegroundColor "Yellow"}
			"I" {write-host "$($currentTime) --> $($logtext)" -ForegroundColor "Gray"}
			"H" {write-host "$($currentTime) --> $($logtext)" -ForegroundColor "Green" -BackgroundColor "DarkGray"}
			default {write-host "$($currentTime) --> $($logtext)" -ForegroundColor "Gray"}
		}
	}
	
	if ($writeToEventLog)
	{
		New-EventLog -LogName "Application" -Source "$($scriptBaseName)" -ErrorAction SilentlyContinue
		switch ($logerr)
		{
			"E" {Write-EventLog -LogName Application -Source "$($scriptBaseName)" -EntryType Error -EventId 8109 -Message $logText.Replace("`t", "")}
			"W" {Write-EventLog -LogName Application -Source "$($scriptBaseName)" -EntryType Warning -EventId 8110 -Message $logText.Replace("`t", "")}
			"I" {Write-EventLog -LogName Application -Source "$($scriptBaseName)" -EntryType Information -EventId 8111 -Message $logText.Replace("`t", "")}
			default {Write-EventLog -LogName Application -Source "$($scriptBaseName)" -EntryType Information -EventId 8111 -Message $logText.Replace("`t", "")}
		}
	}

	if ($writeToFile -and ($LogFile -ne ""))
	{
		try
		{
			$stream = new-Object System.IO.FileStream -ArgumentList "$($logFile)", "Append", "Write", "Read"
	    	$writer = New-Object System.IO.StreamWriter -ArgumentList $stream
			$writer.WriteLine("$($logerr) $($currentTime) --> $($logtext)")
		}
		finally
		{
			if ($writer -ne $NULL)
			{
				$writer.Close()
			}
		}
	}
}

Function Run-AsAdmin ([System.Management.Automation.InvocationInfo]$scriptInvocation)
{
    $windowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent
    $windowsPrincipal = new-object System.Security.Principal.WindowsPrincipal($windowsID)
    $adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
 
    if (!($windowsPrincipal.IsInRole($adminRole)))
    {
        $scriptPath = '"' + $scriptInvocation.MyCommand.Path + '"'
		[string[]]$argList = @('-NoLogo -NoProfile', '-ExecutionPolicy Bypass', '-File', $scriptPath)
		
		$argList += $scriptInvocation.BoundParameters.GetEnumerator() | Foreach {"-$($_.Key)", "$($_.Value)"}
        $argList += $scriptInvocation.UnboundArguments

        try
        {    
            $process = Start-Process PowerShell.exe -PassThru -Verb Runas -Wait -WorkingDirectory $pwd -ArgumentList $argList
            exit $process.ExitCode
        }
        catch {}
        Exit 1
    }
}

Function ProcExt ([string]$fExtension, [string]$fProgId, [string]$fAppName)
{
	$xmlNode = $appAssocXml.DefaultAssociations.Association | Where Identifier -eq $fExtension
	$newNode = $appAssocXml.CreateElement("Association")
	$attrIdentifier = $appAssocXml.CreateAttribute("Identifier")
	$attrIdentifier.Value = "$($fExtension)"
	$attrProgId = $appAssocXml.CreateAttribute("ProgId")
	$attrProgId.Value = "$($fProgId)"
	$attrAppName = $appAssocXml.CreateAttribute("ApplicationName")
	$attrAppName.Value = "$($fAppName)"
	$newNode.Attributes.Append($attrIdentifier)
	$newNode.Attributes.Append($attrProgId)
	$newNode.Attributes.Append($attrAppName)

	if (!([string]::IsNullOrEmpty($xmlNode)))
	{
		$currentApp = $xmlNode.ApplicationName
		Write-Log "Extension is currently assigned to $($currentApp). Overwriting." "I"
		$rootNode.ReplaceChild($newNode, $xmlNode)
		$appAssocXml.Save($Path)
	}
	else
	{
		Write-Log "Extension is currently not assigned to an application. Adding new." "I"
		$rootNode.AppendChild($newNode)
		$appAssocXml.Save($Path)
	}
}

#Run-AsAdmin ($MyInvocation)


if (!(Test-Path($Path)) -or [string]::IsNullOrEmpty($Path))
{
	Write-Log "Could not find XML file provided in 'Path' variable." "I"
	if ($CreateIfNotExists)
	{
		$out = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>`n<DefaultAssociations>`n</DefaultAssociations>"
		try 
		{
			Write-Log "Creating new file `"$($Path)`"." "I"
			$out | Out-File -FilePath $Path -ErrorAction Stop	
		}
		catch 
		{
			Write-Log "Error! Could not create file `"$($Path)`"." "E"
			Exit 8
		}
	}
	else
	{
		Exit 7	
	}
}

$Path = (Get-Item $Path).FullName
$appAssocXml = [xml](get-content $Path)
$rootNode = $appAssocXml.SelectSingleNode("DefaultAssociations")

$extensions = "$($Extension),"

$arrExtensions = $extensions.Split(",", [System.StringSplitOptions]::RemoveEmptyEntries)
foreach ($item in $arrExtensions)
{
	if (!($item.StartsWith(".")))
	{
		$item = ".$($item)"
	}
	ProcExt $item.ToLower() $ProgId $AppName
}