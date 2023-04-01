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

    Describe "Microsoft Defender for Cloud should be connected" -Tag "DfC" {
        It "SecurityAlert (DfC) should have current data" {
            $FirstRowReturned = Invoke-WorkspaceQuery -WorkspaceQueryUri $WorkspaceQueryUri -Query "SecurityAlert | where TimeGenerated > ago(90d) | where ProductName == 'Azure Security Center' | summarize max(TimeGenerated)" | Select-Object -First 1
            $FirstRowReturned | Should -Not -BeNullOrEmpty
        }
    }

}