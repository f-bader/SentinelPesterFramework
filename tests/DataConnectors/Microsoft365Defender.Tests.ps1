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

    Describe "Microsoft 365 Defender should be connected" -Tag "M365D" {

        It "SecurityIncident (M365D) should have current data (14d)" {
            $FirstRowReturned = Invoke-WorkspaceQuery -WorkspaceQueryUri $WorkspaceQueryUri -Query "SecurityIncident | where TimeGenerated > ago(14d) | where ProviderName == 'Microsoft 365 Defender' | summarize max(TimeGenerated)" | Select-Object -First 1
            $FirstRowReturned | Should -Not -BeNullOrEmpty
        }

        It "SecurityAlert (M365D) should have current data (14d)" {
            $FirstRowReturned = Invoke-WorkspaceQuery -WorkspaceQueryUri $WorkspaceQueryUri -Query 'SecurityAlert |where TimeGenerated > ago(14d) |  where ProductName in ("Microsoft Defender Advanced Threat Protection","Office 365 Advanced Threat Protection","Azure Advanced Threat Protection","Microsoft Cloud App Security","Microsoft 365 Defender") | summarize max(TimeGenerated)' | Select-Object -First 1
            $FirstRowReturned | Should -Not -BeNullOrEmpty
        }

        It "<name> should have current data (<maxage>)" -ForEach @(
            @{ Name = "DeviceEvents" ; MaxAge = "1d" }
            @{ Name = "DeviceFileEvents" ; MaxAge = "1d" }
            @{ Name = "DeviceImageLoadEvents" ; MaxAge = "1d" }
            @{ Name = "DeviceInfo" ; MaxAge = "1d" }
            @{ Name = "DeviceLogonEvents" ; MaxAge = "1d" }
            @{ Name = "DeviceNetworkEvents" ; MaxAge = "1d" }
            @{ Name = "DeviceNetworkInfo" ; MaxAge = "1d" }
            @{ Name = "DeviceProcessEvents" ; MaxAge = "1d" }
            @{ Name = "DeviceRegistryEvents" ; MaxAge = "1d" }
            @{ Name = "DeviceFileCertificateInfo" ; MaxAge = "1d" }
            @{ Name = "EmailEvents" ; MaxAge = "1d" }
            @{ Name = "EmailUrlInfo" ; MaxAge = "1d" }
            @{ Name = "EmailAttachmentInfo" ; MaxAge = "1d" }
            @{ Name = "EmailPostDeliveryEvents" ; MaxAge = "1d" }
            @{ Name = "UrlClickEvents" ; MaxAge = "1d" }
            @{ Name = "IdentityLogonEvents" ; MaxAge = "1d" }
            @{ Name = "IdentityQueryEvents" ; MaxAge = "1d" }
            @{ Name = "IdentityDirectoryEvents" ; MaxAge = "1d" }
            @{ Name = "CloudAppEvents" ; MaxAge = "1d" }
            @{ Name = "AlertInfo" ; MaxAge = "7d" }
            @{ Name = "AlertEvidence" ; MaxAge = "90d" }
        ) {
            $FirstRowReturned = Invoke-WorkspaceQuery -WorkspaceQueryUri $WorkspaceQueryUri -Query "$name | where TimeGenerated > ago($MaxAge) | summarize max(TimeGenerated)" | Select-Object -First 1
            $FirstRowReturned | Should -Not -BeNullOrEmpty
        }
    }
}