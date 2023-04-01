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

    Describe "Windows Firewall should be connected" -Tag "WinFirewall" {
        It "WindowsFirewall should have current data (1d)" {
            $FirstRowReturned = Invoke-WorkspaceQuery -WorkspaceQueryUri $WorkspaceQueryUri -Query "WindowsFirewall | where TimeGenerated > ago(1d) |  summarize max(TimeGenerated)" | Select-Object -First 1
            $FirstRowReturned | Should -Not -BeNullOrEmpty
        }
    }

}