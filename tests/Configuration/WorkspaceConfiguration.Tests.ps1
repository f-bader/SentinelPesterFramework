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
    # More information about the setting can be found here:
    # https://learn.microsoft.com/en-us/rest/api/loganalytics/workspaces/update?tabs=HTTP
    $RestUri = "https://management.azure.com/subscriptions/{0}/resourcegroups/{1}/providers/Microsoft.OperationalInsights/workspaces/{2}?api-version=2021-12-01-preview" -f $subscriptionId, $resourceGroup, $workspaceName
    $WorkspaceProperties = Invoke-AzRestMethod -Method GET -Uri $RestUri | Select-Object -ExpandProperty Content | ConvertFrom-Json
}


Describe "Workspace Configuration" -Tag "Configuration", "Workspace" {

    It "Workspace should be located in West Europe" {
        $WorkspaceProperties.location | Should -Be "westeurope"
    }

    It "Workspace retention is set to 90 days" {
        $WorkspaceProperties.properties.retentionInDays | Should -Be 90
    }

    It "Workspace capping should be disabled" {
        $WorkspaceProperties.properties.workspaceCapping.dailyQuotaGb | Should -Be -1
    }

    It "Workspace access control mode should be `"Use resource or workspace permissions`"" {
        $WorkspaceProperties.properties.features.enableLogAccessUsingOnlyResourcePermissions | Should -Be $true
    }

    It "Workspace sku should be `"PerGB2018`"" {
        $WorkspaceProperties.properties.sku.name | Should -Be "PerGB2018"
    }

    It "Workspace should not have a capacity reservation" {
        $WorkspaceProperties.properties.sku.capacityReservationLevel | Should -BeNullOrEmpty
    }

    It "Workspace should not purge data immediately" {
        $WorkspaceProperties.properties.purgeDataImmediately | Should -BeNullOrEmpty
    }

    It "Workspace should have a cannot-delete lock" {
        # A read-only lock on a Log Analytics workspace prevents User and Entity Behavior Analytics (UEBA) from being enabled.
        # A cannot-delete lock on a Log Analytics workspace doesn't prevent data purge operations, remove the data purge role from the user instead.
        # https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/lock-resources?tabs=json#:~:text=A%20read%2Donly%20lock%20on%20a%20Log,data%20purge%20role%20from%20the%20user%20instead.
        $RestUri = "https://management.azure.com/subscriptions/{0}/resourcegroups/{1}/providers/Microsoft.OperationalInsights/workspaces/{2}/providers/Microsoft.Authorization/locks?api-version=2016-09-01" -f $subscriptionId, $resourceGroup, $workspaceName
        $ResourceLock = Invoke-AzRestMethod -Method GET -Uri $RestUri | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty value
        $ResourceLock.properties.level | Should -Be "CanNotDelete"
    }

}