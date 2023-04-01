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

BeforeDiscovery {
    # Define the Analytics rule ids that should be present and enabled
    $AnalyticsRuleIds = @(
        "BuiltInFusion",
        "b38656e6-ee25-48f6-baee-741be171b174",
        "0f897683-8af5-4e42-b256-98cc00c3e3c1",
        "7a2a0966-8f10-4498-b627-b1dfd8186c83",
        "8b713b44-6ee0-4c47-817a-d1b6b4213d8e",
        "a4fe163e-aec6-407c-8240-ef280742a5f4"
    )
}


BeforeAll {
    # More information about the API can be found here:
    # https://learn.microsoft.com/en-us/rest/api/securityinsights/stable/alert-rules/list?tabs=HTTP
    # Query Analytics rules
    $RestUri = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.OperationalInsights/workspaces/{2}/providers/Microsoft.SecurityInsights/alertRules?api-version=2022-11-01" -f $subscriptionId, $resourceGroup, $workspaceName
    $CurrentItems = Invoke-AzRestMethod -Method GET -Uri $RestUri | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty value
}

Describe "Analytics Rules" -Tag "AnalyticsRules" {

    It "Analytics rules should not be in state `"AUTO DISABLED`"" {
        # https://learn.microsoft.com/en-us/azure/sentinel/detect-threats-custom#issue-a-scheduled-rule-failed-to-execute-or-appears-with-auto-disabled-added-to-the-name
        $CurrentItems | Where-Object { $_.properties.displayName -match "AUTO DISABLED" } | Should -BeNullOrEmpty
    }

    It "Analytics rule <_> is present" -ForEach @( $AnalyticsRuleIds ) {
        $AnalyticsRuleId = $_
        $AnalyticsRule = $CurrentItems | Where-Object { $_.id -match $AnalyticsRuleId }
        $AnalyticsRule.id | Should -Match $AnalyticsRuleId
    }

    It "Analytics rule <_> is enabled" -ForEach @( $AnalyticsRuleIds ) {
        $AnalyticsRuleId = $_
        $AnalyticsRule = $CurrentItems | Where-Object { $_.id -match $AnalyticsRuleId }
        $AnalyticsRule.properties.enabled | Should -Be $true
    }
}