﻿#########################################################################################################
# This PowerShell script will prompt you for:								#
#    * Admin credentials for a user who can run the Get-MailboxFolderStatistics cmdlet in Exchange	#
#      Online and who is an eDiscovery Manager in the Security &amp; Compliance Center.			#
# The script will then:											#
#    * If an email address is supplied: list the folders for the target mailbox.			#
#    * If a SharePoint or OneDrive for Business site is supplied: list the folder paths for the site.	#
#    * In both cases, the script supplies the correct search properties (folderid: or path:)		#
#      appended to the folder ID or path ID to use in a Content Search.				#
# Notes:												#
#    * For SharePoint and OneDrive for Business, the paths are searched recursively; this means the 	#
#      the current folder and all sub-folders are searched.						#
#    * For Exchange, only the specified folder will be searched; this means sub-folders in the folder	#
#      will not be searched.  To search sub-folders, you need to use the specify the folder ID for	#
#      each sub-folder that you want to search.								#
#    * For Exchange, only folders in the user's primary mailbox will be returned by the script.		#
#########################################################################################################
# Collect the target email address or SharePoint Url
$addressOrSite = Read-Host "https://vegvesen-my.sharepoint.com/personal/glenyg_vegvesen_no/Documents/"
# Authenticate with Exchange Online and the Security &amp; Compliance Center (Exchange Online Protection - EOP)
if (!$credentials)
{
    $credentials = Get-Credential
}
if ($addressOrSite.IndexOf("@") -ige 0)
{
    # List the folder Ids for the target mailbox
    $emailAddress = $addressOrSite
    # Authenticate with Exchange Online
    if (!$ExoSession)
    {
        $ExoSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell-liveid/ -Credential $credentials -Authentication Basic -AllowRedirection
        Import-PSSession $ExoSession -AllowClobber -DisableNameChecking
    }
    $folderQueries = @()
    $folderStatistics = Get-MailboxFolderStatistics $emailAddress
    foreach ($folderStatistic in $folderStatistics)
    {
        $folderId = $folderStatistic.FolderId;
        $folderPath = $folderStatistic.FolderPath;
        $encoding= [System.Text.Encoding]::GetEncoding("us-ascii")
        $nibbler= $encoding.GetBytes("0123456789ABCDEF");
        $folderIdBytes = [Convert]::FromBase64String($folderId);
        $indexIdBytes = New-Object byte[] 48;
        $indexIdIdx=0;
        $folderIdBytes | select -skip 23 -First 24 | %{$indexIdBytes[$indexIdIdx++]=$nibbler[$_ -shr 4];$indexIdBytes[$indexIdIdx++]=$nibbler[$_ -band 0xF]}
        $folderQuery = "folderid:$($encoding.GetString($indexIdBytes))";
        $folderStat = New-Object PSObject
        Add-Member -InputObject $folderStat -MemberType NoteProperty -Name FolderPath -Value $folderPath
        Add-Member -InputObject $folderStat -MemberType NoteProperty -Name FolderQuery -Value $folderQuery
        $folderQueries += $folderStat
    }
    Write-Host "-----Exchange Folders-----"
    $folderQueries |ft
}
elseif ($addressOrSite.IndexOf("http") -ige 0)
{
    $searchName = "SPFoldersSearch"
    $searchActionName = "SPFoldersSearch_Preview"
    # List the folders for the SharePoint or OneDrive for Business Site
    $siteUrl = $addressOrSite
    # Authenticate with the Security &amp; Compliance Center
    if (!$SccSession)
    {
        $SccSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid -Credential $credentials -Authentication Basic -AllowRedirection
        Import-PSSession $SccSession -AllowClobber -DisableNameChecking
    }
    # Clean-up, if the script was aborted, the search we created might not have been deleted.  Try to do so now.
    Remove-ComplianceSearch $searchName -Confirm:$false -ErrorAction 'SilentlyContinue'
    # Create a Content Search against the SharePoint Site or OneDrive for Business site and only search for folders; wait for the search to complete
    $complianceSearch = New-ComplianceSearch -Name $searchName -ContentMatchQuery "contenttype:folder" -SharePointLocation $siteUrl
    Start-ComplianceSearch $searchName
    do{
        Write-host "Waiting for search to complete..."
        Start-Sleep -s 5
        $complianceSearch = Get-ComplianceSearch $searchName
    }while ($complianceSearch.Status -ne 'Completed')
    if ($complianceSearch.Items -gt 0)
    {
        # Create a Compliance Search Action and wait for it to complete. The folders will be listed in the .Results parameter
        $complianceSearchAction = New-ComplianceSearchAction -SearchName $searchName -Preview
        do
        {
            Write-host "Waiting for search action to complete..."
            Start-Sleep -s 5
            $complianceSearchAction = Get-ComplianceSearchAction $searchActionName
        }while ($complianceSearchAction.Status -ne 'Completed')
        # Get the results and print out the folders
        $results = $complianceSearchAction.Results
        $matches = Select-String "Data Link:.+[,}]" -Input $results -AllMatches
        foreach ($match in $matches.Matches)
        {
            $rawUrl = $match.Value
            $rawUrl = $rawUrl -replace "Data Link: " -replace "," -replace "}"
            Write-Host "path:""$rawUrl"""
        }
    }
    else
    {
        Write-Host "No folders were found for $siteUrl"
    }
    Remove-ComplianceSearch $searchName -Confirm:$false -ErrorAction 'SilentlyContinue'
}
else
{
    Write-Error "Couldn't recognize $addressOrSite as an email address or a site URL"
}



https://vegvesen-my.sharepoint.com/personal/glenyg_vegvesen_no/Documents/Applocker%20SVV.docx?web=1