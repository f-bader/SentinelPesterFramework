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

    # More information about the setting can be found here:
    # https://learn.microsoft.com/en-us/rest/api/securityinsights/preview/product-settings/update?tabs=HTTP
    # https://learn.microsoft.com/en-us/azure/templates/microsoft.securityinsights/settings?pivots=deployment-language-arm-template

    # Query UEBA settings
    $RestUri = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.OperationalInsights/workspaces/{2}/providers/Microsoft.SecurityInsights/settings?api-version=2022-12-01-preview" -f $subscriptionId, $resourceGroup, $workspaceName
    $SentinelSettings = Invoke-AzRestMethod -Method GET -Uri $RestUri | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty value

    $RestUri = "https://management.azure.com/subscriptions/{0}/resourcegroups/{1}/providers/microsoft.operationalinsights/workspaces/{2}/providers/Microsoft.SecurityInsights/settings/SentinelHealth/providers/microsoft.insights/diagnosticSettings?api-version=2021-05-01-preview" -f $subscriptionId, $resourceGroup, $workspaceName
    $DiagnosticSettings = Invoke-AzRestMethod -Method GET -Uri $RestUri | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty value
}

Describe "Sentinel Configuration" -Tag "Configuration", "Sentinel" {

    It "UEBA Source <_> is enabled" -ForEach "AuditLogs", "SecurityEvent", "SigninLogs", "AzureActivity" -Tag "UEBA" {
        $SentinelSettings | Where-Object name -eq "Ueba"  | Select-Object -ExpandProperty properties | Select-Object -ExpandProperty dataSources | Should -Contain $_
    }

    It "EntityAnalytics source <_> is enabled" -ForEach "ActiveDirectory", "AzureActiveDirectory" -Tag "EntityAnalytics" {
        $SentinelSettings | Where-Object name -eq "EntityAnalytics" | Select-Object -ExpandProperty properties | Select-Object -ExpandProperty entityProviders | Should -Contain $_
    }

    It "Anomalies is enabled" -Tag "Anomalies" {
        $SentinelSettings | Where-Object name -eq "Anomalies" | Select-Object -ExpandProperty properties | Select-Object -ExpandProperty isEnabled | Should -Be $true
    }

    It "Microsoft data access is enabled (EyesOn)" -Tag "EyesOn" {
        $SentinelSettings | Where-Object name -eq "EyesOn" | Select-Object -ExpandProperty properties | Select-Object -ExpandProperty isEnabled | Should -Be $true
    }

    It "Diagnostic settings are send to the same Log Analytics workspace" -Tag "DiagnosticSettings" {
        $DiagnosticSettings.id -like "$($DiagnosticSettings.properties.workspaceId)*" | Should -Be $true
    }

    It "All diagnostic settings are enabled" -Tag "DiagnosticSettings" {
        $DiagnosticSettings.properties.logs | Where-Object enabled -eq $false | Should -BeNullOrEmpty
    }

    It "SentinelHealth should have current data (1d)" {
        $FirstRowReturned = Invoke-WorkspaceQuery -WorkspaceQueryUri $WorkspaceQueryUri -Query "SentinelHealth | where TimeGenerated > ago(1d) | summarize max(TimeGenerated)" | Select-Object -First 1
        $FirstRowReturned | Should -Not -BeNullOrEmpty
    }
}