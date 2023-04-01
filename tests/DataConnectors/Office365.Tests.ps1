param (
    [Parameter(Mandatory = $true)]
    [string]$workspaceName,

    [Parameter(Mandatory = $true)]
    [string]$resourceGroup,

    [Parameter(Mandatory = $true)]
    [string]$subscriptionId,

    [Parameter(Mandatory = $false)]
    [string]$CICDPathRoot
)

BeforeAll {

    # Import the helper functions
    . ./src/WorkspaceHelper.ps1
    $params = @{
        "subscriptionId" = $subscriptionId
        "resourceGroup"  = $resourceGroup
        "workspaceName"  = $workspaceName
    }
    $WorkspaceQueryUri = Get-WorkspaceQueryUri @params
}

Describe "Sentinel Dataconnectors" -Tag "DataConnector" {

    Describe "Office 365 should be connected" -Tag "O365" {

        It "Office 365 OfficeActivity (SharePoint) should have current data (1d)" -Tag "O365-SharePoint" {
            $FirstRowReturned = Invoke-WorkspaceQuery -WorkspaceQueryUri $WorkspaceQueryUri -Query 'OfficeActivity | where TimeGenerated > ago(1d) | where OfficeWorkload == "SharePoint" or OfficeWorkload == "OneDrive" | summarize max(TimeGenerated)' | Select-Object -First 1
            $FirstRowReturned | Should -Not -BeNullOrEmpty
        }

        It "Office 365 OfficeActivity (Exchange) should have current data (1d)" -Tag "O365-Exchange" {
            $FirstRowReturned = Invoke-WorkspaceQuery -WorkspaceQueryUri $WorkspaceQueryUri -Query 'OfficeActivity | where TimeGenerated > ago(1d) | where OfficeWorkload == "Exchange" | summarize max(TimeGenerated)' | Select-Object -First 1
            $FirstRowReturned | Should -Not -BeNullOrEmpty
        }

        It "Office 365 OfficeActivity (Teams) should have current data (1d)" -Tag "O365-Teams" {
            $FirstRowReturned = Invoke-WorkspaceQuery -WorkspaceQueryUri $WorkspaceQueryUri -Query 'OfficeActivity | where TimeGenerated > ago(1d) | where OfficeWorkload == "MicrosoftTeams" | summarize max(TimeGenerated)' | Select-Object -First 1
            $FirstRowReturned | Should -Not -BeNullOrEmpty
        }
    }
}