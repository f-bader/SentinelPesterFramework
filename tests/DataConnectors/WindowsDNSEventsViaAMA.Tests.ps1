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

    Describe "Windows DNS Events via AMA should be connected" -Tag "AMADNS" {
        It "ASimDnsActivityLogs (Microsoft DNS Server) should have current data (1d)" {
            $FirstRowReturned = Invoke-WorkspaceQuery -WorkspaceQueryUri $WorkspaceQueryUri -Query 'ASimDnsActivityLogs | where TimeGenerated > ago(1d) | where EventProduct == "DNS Server" | where EventVendor == "Microsoft" | summarize max(TimeGenerated)' | Select-Object -First 1
            $FirstRowReturned | Should -Not -BeNullOrEmpty
        }
    }

}