#Get-AzResource -ResourceType "Microsoft.Automation/automationAccounts"

Get-AzResource -ResourceType "Microsoft.OperationalInsights/workspaces"

# må registrere subscription mot Microsof.insight

Connect-AzAccount


$workspaceId = "/subscriptions/c7213183-ebd0-4104-a494-0c33d7fa8e35/resourceGroups/RG_MCAS/providers/Microsoft.Automation/automationAccounts/MCAS-Clear-RecycleBin"

$automationAccountId = "/subscriptions/c7213183-ebd0-4104-a494-0c33d7fa8e35/resourceGroups/LogAnalytics/providers/Microsoft.OperationalInsights/workspaces/SVVAzureAutomation"


Set-AzDiagnosticSetting -ResourceId $automationAccountId -WorkspaceId $workspaceId -Enabled 1

Disconnect-AzAccount



