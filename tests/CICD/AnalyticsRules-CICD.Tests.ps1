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
    if ( $CICDPathRoot ) {
        $AnalyticsRulePath = Join-Path $CICDPathRoot "AnalyticsRules"
        if ( Test-Path $AnalyticsRulePath ) {
            #region Create a test list of Analytics Rules
            $ArmTemplates = Get-ChildItem $AnalyticsRulePath -Recurse -File *.json
            $AnalyticsRulesDefinition = New-Object -TypeName 'System.Collections.ArrayList'

            foreach ($ArmTemplate in $ArmTemplates) {
                $ArmTemplateJSON = Get-Content $ArmTemplate.FullName | ConvertFrom-Json
                if ($ArmTemplateJSON.resources.id -match "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}") {
                    $Id = $Matches[0]
                    $TempHashTable = @{
                        "id"    = $Id
                        "name"  = $ArmTemplateJSON.resources.properties.displayName
                        "query" = $ArmTemplateJSON.resources.properties.query
                    }
                    $AnalyticsRulesDefinition.Add($TempHashTable) | Out-Null
                } else {
                    Write-Warning "Could not read Analytics Rules id from file $($ArmTemplate.FullName). Skipping test for this artifact."
                }
            }
            #endregion
        }
    }
}

BeforeAll {
    # More information about the API can be found here:
    # https://learn.microsoft.com/en-us/rest/api/securityinsights/stable/alert-rules/list?tabs=HTTP
    # Query Analytics rules
    $RestUri = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.OperationalInsights/workspaces/{2}/providers/Microsoft.SecurityInsights/alertRules?api-version=2022-11-01" -f $subscriptionId, $resourceGroup, $workspaceName
    $CurrentItems = Invoke-AzRestMethod -Method GET -Uri $RestUri | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty value
}

Describe "Analytics Rules" -Tag "AnalyticsRules-CICD" {

    It "Analytics rules should not be in state `"AUTO DISABLED`"" {
        # https://learn.microsoft.com/en-us/azure/sentinel/detect-threats-custom#issue-a-scheduled-rule-failed-to-execute-or-appears-with-auto-disabled-added-to-the-name
        $CurrentItems | Where-Object { $_.properties.displayName -match "AUTO DISABLED" } | Should -BeNullOrEmpty
    }

    It "Analytics rule <id> is present" -ForEach $AnalyticsRulesDefinition {
        $Item = $CurrentItems | Where-Object { $_.id -match $id }
        $Item.id | Should -Match $id
    }

    It "Analytics rule <id> name is set to <name>" -ForEach $AnalyticsRulesDefinition {
        $Item = $CurrentItems | Where-Object { $_.id -match $id }
        $Item.properties.displayName | Should -Be $name
    }

    It "Analytics rule <id> is enabled" -ForEach $Global:AnalyticsRulesDefinition {
        $Item = $CurrentItems | Where-Object { $_.id -match $id }
        $Item.properties.enabled | Should -Be $true
    }
}