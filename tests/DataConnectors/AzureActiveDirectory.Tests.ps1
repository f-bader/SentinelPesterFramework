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
    Describe "Azure Active Directory should be connected" -Tag "AAD" {
        It "<name> should have current data (<maxage>)" -ForEach @(
            @{ Name = "SigninLogs" ; MaxAge = "1d" }
            @{ Name = "AuditLogs" ; MaxAge = "1d" }
            @{ Name = "AADNonInteractiveUserSignInLogs" ; MaxAge = "1d" }
            @{ Name = "AADServicePrincipalSignInLogs" ; MaxAge = "1d" }
            @{ Name = "AADManagedIdentitySignInLogs" ; MaxAge = "1d" }
            @{ Name = "AADProvisioningLogs" ; MaxAge = "1d" }
            @{ Name = "ADFSSignInLogs" ; MaxAge = "1d" }
            @{ Name = "AADUserRiskEvents" ; MaxAge = "30d" }
            @{ Name = "AADRiskyUsers" ; MaxAge = "30d" }
            @{ Name = "NetworkAccessTraffic" ; MaxAge = "1d" }
            @{ Name = "AADRiskyServicePrincipals" ; MaxAge = "30d" }
            @{ Name = "AADServicePrincipalRiskEvents" ; MaxAge = "30d" }
        ) {
            $FirstRowReturned = Invoke-WorkspaceQuery -WorkspaceQueryUri $WorkspaceQueryUri -Query "$name | where TimeGenerated > ago($MaxAge) | summarize max(TimeGenerated)" | Select-Object -First 1
            $FirstRowReturned | Should -Not -BeNullOrEmpty
        }
    }
}