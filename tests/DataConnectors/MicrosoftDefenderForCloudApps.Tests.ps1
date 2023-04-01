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

    Describe "Microsoft Defender for Cloud Apps should be connected" -Tag "MDA" {
        It "SecurityAlert (MDA) should have current data" {
            $FirstRowReturned = Invoke-WorkspaceQuery -WorkspaceQueryUri $WorkspaceQueryUri -Query "SecurityAlert | where TimeGenerated > ago(90d) | where ProductName == 'Microsoft Cloud App Security' | summarize max(TimeGenerated)" | Select-Object -First 1
            $FirstRowReturned | Should -Not -BeNullOrEmpty
        }

        It "McasShadowItReporting should have current data" -Tag "MDA-ShadowIT" {
            $FirstRowReturned = Invoke-WorkspaceQuery -WorkspaceQueryUri $WorkspaceQueryUri -Query "McasShadowItReporting | where TimeGenerated > ago(7d) | summarize max(TimeGenerated)" | Select-Object -First 1
            $FirstRowReturned | Should -Not -BeNullOrEmpty
        }
    }

}