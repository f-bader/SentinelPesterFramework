param (
    [Parameter(Mandatory = $true)]
    [string]$workspaceName,

    [Parameter(Mandatory = $true)]
    [string]$resourceGroup,

    [Parameter(Mandatory = $true)]
    [string]$subscriptionId,

    [Parameter(Mandatory = $false)]
    [string]
    $CICDPathRoot
)

BeforeDiscovery {
    if ($CICDPathRoot) {
        $AutomationRulesPath = Join-Path $CICDPathRoot "AutomationRules"
        if ( $AutomationRulesPath ) {
            #region Create a test list of Automation Rules
            $ArmTemplates = Get-ChildItem $AutomationRulesPath -Recurse -File *.json
            $AutomationRulesDefinition = New-Object -TypeName 'System.Collections.ArrayList'

            foreach ($ArmTemplate in $ArmTemplates) {
                $ArmTemplateJSON = Get-Content $ArmTemplate.FullName | ConvertFrom-Json
                $TempHashTable = @{
                    "id"      = $ArmTemplateJSON.resources.name
                    "order"   = $ArmTemplateJSON.resources.properties.order
                    "enabled" = $ArmTemplateJSON.resources.properties.triggeringLogic.isEnabled
                }
                $AutomationRulesDefinition.Add($TempHashTable) | Out-Null
            }
            #endregion
        }
    }
}

BeforeAll {
    # More information about the API can be found here:
    #
    # Query current settings
    $RestUri = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.OperationalInsights/workspaces/{2}/providers/Microsoft.SecurityInsights/automationRules?api-version=2022-12-01-preview" -f $subscriptionId, $resourceGroup, $workspaceName
    $CurrentItems = Invoke-AzRestMethod -Method GET -Uri $RestUri | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty value
}

Describe "Automation Rules" -Tag "AutomationRules-CICD" {

    It "Automation rule <id> is present" -ForEach $AutomationRulesDefinition {
        $Item = $CurrentItems | Where-Object { $_.name -match $id }
        $Item.name | Should -Match $id
    }

    It "Automation rule <id> order is set to <order>" -ForEach $AutomationRulesDefinition {
        $Item = $CurrentItems | Where-Object { $_.name -match $id }
        $Item.properties.order | Should -Be $order
    }

    It "Automation rule <id> is <enabled>" -ForEach $AutomationRulesDefinition {
        $Item = $CurrentItems | Where-Object { $_.name -match $id }
        $Item.properties.triggeringLogic.isEnabled | Should -Be $enabled
    }
}
