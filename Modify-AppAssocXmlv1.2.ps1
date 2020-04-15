<#
.SYNOPSIS
    This script creates or modifies a local AppAssoc.xml file, used to set file type associations with group policy. It can also export the Default Associations set on the client to a file.

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

.PARAMETER CreateIfNotExists
    With this option set, a new empty Default associations XML is created, if it doesn't exist.

.PARAMETER Export
    Exports the currently set default associations of the client where the script is run. The path parameter must also be specified.

.PARAMETER SkipUnknown
	Only valid when used with -Export. With this option set, app associations are skipped when the app name cannot be resolved.
	
.NOTES
    Author:   Helmut Wagensonner, Microsoft
	Creation: 13/03/18
	Version:  1.0 - Initial creation
	Version:  1.1 - Supporting mulitple file extensions for "Extension" argument
	Version:  1.2 - Adding support to export current file associations 

.EXAMPLE
    .\Modify-AppAssocXml.ps1 -Path "C:\Users\Public\Microsoft\Windows\AppAssoc.xml" -Logfile "<default>" -Extension ".avi" -AppId "VLC.avi" -AppName "VLC Media Player" -CreateIfNotExists
    .\Modify-AppAssocXml.ps1 -Path "C:\Users\Test\Desktop\Export.XML" -Export -SkipUnknown
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
	
	[Parameter(Mandatory = $false)]
	[string] $Extension, 			#= ".xAy,.XQZ,xqw",
	
	[Parameter(Mandatory = $false)]
	[string] $ProgId, 				#= "Applications\XAYHandler",
	
	[Parameter(Mandatory = $false)]
	[string] $AppName, 				#= "XAY Event Handler 1.0",

	[string] $Logfile = "<default>",

	[switch] $CreateIfNotExists = $false, 

	[switch] $ExportFA = $false,

	[switch] $SkipUnknownApp = $false
)

$psScriptRoot = (Get-Item $MyInvocation.MyCommand.Definition).DirectoryName
$scriptBaseName = (Get-Item $MyInvocation.MyCommand.Definition).BaseName
$tempDirectory = $env:TEMP
$startDate = Get-Date -Format "yyyy-MM-dd HH-mm-ss"
if ($LogFile -eq "<default>")
{
	$LogFile = "$($tempDirectory)\$($scriptBaseName).LOG"
}

$TypeShlWApi = @'
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32; 
using System.Text;

namespace Native 
{
    public class ShlWApi 
    {
        [DllImport("shlwapi.dll", CharSet=CharSet.Unicode)]
        private static extern int SHLoadIndirectString(string strSource, StringBuilder sbOut, int intBuf, string notUsed);

        public static string LoadIndirectString(string strIndirectString)
        {
            try 
            {
                int retVal;
                StringBuilder sbBuffer = new StringBuilder(1024);
                retVal = SHLoadIndirectString(strIndirectString, sbBuffer, 1024, null);

                if (retVal == 0)
                {
                    return sbBuffer.ToString();
                }
                else
                {
                    return "";
                }
            }
            catch
            {
                return "";
            }
        }
    }
}
'@

Add-Type -TypeDefinition $TypeShlWApi -Language CSharp

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
	$windowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
	$windowsPrincipal = new-object System.Security.Principal.WindowsPrincipal($windowsID)
	$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator

	if (!($windowsPrincipal.IsInRole($adminRole)))
	{
		Write-Log "We have a low integrity token. Triggering UAC to run elevated." "I"
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
	else
	{
		Write-Log "We're already elevated." "I"
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

#// Plausibility checks
if ($ExportFA)
{
	if ([string]::IsNullOrEmpty($Path))
	{
		Write-Log "You need to specify a path where to save the exported XMl file." "E"
		Exit 3
	}
}
else
{
	if (([string]::IsNullOrEmpty($Path)) -or ([string]::IsNullOrEmpty($Extension)) -or ([string]::IsNullOrEmpty($ProgId)) -or ([string]::IsNullOrEmpty($AppName)))
	{
		Write-Log "You need to specify values for Path, AppName, ProgID and Extension arguments." "E"
		Exit 3
	}
}

#// Export Default associations
if ($ExportFA)
{
	Write-Log "Writing Header." "I"
	'<?xml version="1.0" encoding="UTF-8"?>' | Out-File -FilePath $Path
	'<DefaultAssociations>' | Out-File -FilePath $Path -Append
	Write-Log "Enumerating FileExts subkeys for user choices." "I"
	$fileExts = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts").GetSubKeyNames()

	foreach ($fileExt in $fileExts)
	{
		$expProgId = ""
		try 
		{
			$expProgId = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$($fileExt)\UserChoice").GetValue("ProgId")
		}
		catch
		{
			
		}
		if ([string]::IsNullOrEmpty($expProgId))
		{
			continue
		}

		#// If we have a custom ProgId set for this extension, get the App Name
		$expAppName = ""
		
		if ([string]::IsNullOrEmpty($expAppName))
		{
			try 
			{
				#// Way 1: Get via MS-Resource inderect string (works for most UWP apps)
				$expAppName = [Microsoft.Win32.Registry]::ClassesRoot.OpenSubKey("$($expProgId)\Application").GetValue("ApplicationName")
				if ($expAppName.StartsWith("@{"))
				{
					$expAppName = [Native.ShlWApi]::LoadIndirectString($expAppName)
				}
			}
			catch
			{
				
			}
		}

		if ([string]::IsNullOrEmpty($expAppName))
		{
			try 
			{
				#// Way 2: Get via file description (works for most Win32 applications)
				$expAppName = [Microsoft.Win32.Registry]::ClassesRoot.OpenSubKey("$($expProgId)\Shell\Open\Command").GetValue("")
				$expAppName = ([Management.Automation.PSParser]::Tokenize($expAppName, [ref]$null))[0].Content
				$expAppName = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($expAppName).FileDescription
			}
			catch
			{
				
			}
		}

		if ([string]::IsNullOrEmpty($expAppName))
		{
			#// If still not found, we have some uknown app.
			$expAppName = "Unknown Application"
			if ($SkipUnknownApp)
			{
				continue
			}
		}

		$expAppName = $expAppName.Replace("`"", "").Replace("&", "&amp;")
		$outString = "`t<Association Identifier=`"$($fileExt)`" ProgId=`"$($expProgId)`" ApplicationName=`"$($expAppName)`" />"
		$outString | Out-File -FilePath $Path -Append
	}

	Write-Log "Writing Footer." "I"
	'</DefaultAssociations>' | Out-File -FilePath $Path -Append

	Write-Log "Default FTAs exported to file." "I"
	Exit 0
}

#// Modify Default associations
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
# SIG # Begin signature block
# MIINEwYJKoZIhvcNAQcCoIINBDCCDQACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUv55lRtr+jCjY3XF4cynQljGn
# i1ugggpVMIIFHTCCBAWgAwIBAgIQCDQmWfF9TyW+LMkSCN2POzANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE3MTIwMTAwMDAwMFoXDTE5MDQw
# NTEyMDAwMFowWjELMAkGA1UEBhMCREUxETAPBgNVBAcTCE1vb3NidXJnMRswGQYD
# VQQKExJIZWxtdXQgV2FnZW5zb25uZXIxGzAZBgNVBAMTEkhlbG11dCBXYWdlbnNv
# bm5lcjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALxXvyuEzRBiXCZO
# oBn9iCoBGb6h8CnTfYmNrsFjmxhVs1OF/MCtTWMculxzigqu91p5Qi44FVCz1ChJ
# l4Lcts4vQ2CRYjjv5EsVFYa0znHhLLF54EofDoPg5WoYjzv42DXQOjCet84rNepa
# iZwQ0gHbVAIdSCHbw0NtZqXfhddIMTMMYTlIkOVncCQ5sUWoQ9VzEE83gsC3iHf1
# JhPUlUk3HOnX3TmVaZJoFKbk0ld5VKmQRN1RCCac5iFSovCQlJ7rvNdrpQ4x7KV8
# MxU8ti1j9IX/2nGz6fAWjKZEdtAvSZQyM2peoZeKk5nt068J4pJh8PUq6cvM2x5I
# Dr4SZ+UCAwEAAaOCAcUwggHBMB8GA1UdIwQYMBaAFFrEuXsqCqOl6nEDwGD5LfZl
# dQ5YMB0GA1UdDgQWBBSqzOdhF/ttUpMEZS1ocudC7nV5+TAOBgNVHQ8BAf8EBAMC
# B4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAwbjA1oDOgMYYvaHR0cDov
# L2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1jcy1nMS5jcmwwNaAzoDGG
# L2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFzc3VyZWQtY3MtZzEuY3Js
# MEwGA1UdIARFMEMwNwYJYIZIAYb9bAMBMCowKAYIKwYBBQUHAgEWHGh0dHBzOi8v
# d3d3LmRpZ2ljZXJ0LmNvbS9DUFMwCAYGZ4EMAQQBMIGEBggrBgEFBQcBAQR4MHYw
# JAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBOBggrBgEFBQcw
# AoZCaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0U0hBMkFzc3Vy
# ZWRJRENvZGVTaWduaW5nQ0EuY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQEL
# BQADggEBACaXWO+ohYm5kinRhFZOF2Yn6LTj1KJE7tlES3QTpSzdZv+ghFU8qQaS
# HilXZ+5PRUY286HP/ZHhkqRVqHCq38L8vop40uHpjhiGAlfFoo9OPebCqia+u9EL
# GmznUNHiOA+mRY9R01LqS6R2Gog/uNkqJ4oFiBjEvmVv1MCsyMgz2m/NWQ03pWvR
# fXJmG33rKhXYo8c8G7z0ei36rXpME9W+TvXDCS+P8wOMrxT4UDkrjtw5Grw988/C
# valDlYqzJV244nm+oJxPw+WK27e6X9jwUZuAvXRYka8WRLtdUbR1PP9h68EXC8P0
# YyvwqzdXW3z2WFYi59qF2taq3LnxnegwggUwMIIEGKADAgECAhAECRgbX9W7ZnVT
# Q7VvlVAIMA0GCSqGSIb3DQEBCwUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxE
# aWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMT
# G0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0xMzEwMjIxMjAwMDBaFw0y
# ODEwMjIxMjAwMDBaMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJ
# bmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lDZXJ0
# IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0EwggEiMA0GCSqGSIb3DQEB
# AQUAA4IBDwAwggEKAoIBAQD407Mcfw4Rr2d3B9MLMUkZz9D7RZmxOttE9X/lqJ3b
# Mtdx6nadBS63j/qSQ8Cl+YnUNxnXtqrwnIal2CWsDnkoOn7p0WfTxvspJ8fTeyOU
# 5JEjlpB3gvmhhCNmElQzUHSxKCa7JGnCwlLyFGeKiUXULaGj6YgsIJWuHEqHCN8M
# 9eJNYBi+qsSyrnAxZjNxPqxwoqvOf+l8y5Kh5TsxHM/q8grkV7tKtel05iv+bMt+
# dDk2DZDv5LVOpKnqagqrhPOsZ061xPeM0SAlI+sIZD5SlsHyDxL0xY4PwaLoLFH3
# c7y9hbFig3NBggfkOItqcyDQD2RzPJ6fpjOp/RnfJZPRAgMBAAGjggHNMIIByTAS
# BgNVHRMBAf8ECDAGAQH/AgEAMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAKBggr
# BgEFBQcDAzB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3Nw
# LmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDCBgQYDVR0fBHoweDA6
# oDigNoY0aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElE
# Um9vdENBLmNybDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lD
# ZXJ0QXNzdXJlZElEUm9vdENBLmNybDBPBgNVHSAESDBGMDgGCmCGSAGG/WwAAgQw
# KjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAKBghg
# hkgBhv1sAzAdBgNVHQ4EFgQUWsS5eyoKo6XqcQPAYPkt9mV1DlgwHwYDVR0jBBgw
# FoAUReuir/SSy4IxLVGLp6chnfNtyA8wDQYJKoZIhvcNAQELBQADggEBAD7sDVok
# s/Mi0RXILHwlKXaoHV0cLToaxO8wYdd+C2D9wz0PxK+L/e8q3yBVN7Dh9tGSdQ9R
# tG6ljlriXiSBThCk7j9xjmMOE0ut119EefM2FAaK95xGTlz/kLEbBw6RFfu6r7VR
# wo0kriTGxycqoSkoGjpxKAI8LpGjwCUR4pwUR6F6aGivm6dcIFzZcbEMj7uo+MUS
# aJ/PQMtARKUT8OZkDCUIQjKyNookAv4vcn4c10lFluhZHen6dGRrsutmQ9qzsIzV
# 6Q3d9gEgzpkxYz0IGhizgZtPxpMQBvwHgfqL2vmCSfdibqFT+hKUGIUukpHqaGxE
# MrJmoecYpJpkUe8xggIoMIICJAIBATCBhjByMQswCQYDVQQGEwJVUzEVMBMGA1UE
# ChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYD
# VQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgQ29kZSBTaWduaW5nIENBAhAI
# NCZZ8X1PJb4syRII3Y87MAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQowCKAC
# gAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsx
# DjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBSpJe0i6TwRRcfIERU4pMA+
# twGpmzANBgkqhkiG9w0BAQEFAASCAQCrrmHx9AWfkwUmXIsF+ts4+uQ/E3GIjzEG
# O7wPegeq+eIEmH9T4eoGj6TSeofwrZQGhw1BeKQoFNS3kJ2Fxbjw3Smo5u1z0Cm6
# Hf9c67E2pZZDfUhIIohPQvG0FqDXxk7UqCo8sqc/agCE21jIueae43hvKIlJqkfi
# XatatBePjuno2pVtsOgVaxJQSpAgEvRfwB6i8GfIUPAfVTOFP4NJqvppwsc5Qi3D
# bFUj3807Le6/6tOeZaZIQmFVv5ow1qJWVo9Ib00k41IPy0i//RlIT1mg3AGzR8zp
# 9Uv5LD1hrw6T0xxtTHfVaVbrN0Hmqu6Xj/+xts+Q6C3rpg2OpR2v
# SIG # End signature block
