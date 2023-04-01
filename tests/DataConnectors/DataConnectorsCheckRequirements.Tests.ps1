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
    $DataConnectorsToCheck = @(
        #"APIPolling",
        "AmazonWebServicesCloudTrail",
        "AmazonWebServicesS3",
        "AzureActiveDirectory",
        "AzureAdvancedThreatProtection",
        #"AzureSecurityCenter",
        "Dynamics365",
        #"GenericUI",
        #"IOT",
        "MicrosoftCloudAppSecurity",
        "MicrosoftDefenderAdvancedThreatProtection",
        "MicrosoftThreatIntelligence",
        "MicrosoftThreatProtection",
        "Office365",
        "Office365Project",
        "OfficeATP",
        "OfficeIRM",
        "OfficePowerBI",
        "ThreatIntelligence",
        "ThreatIntelligenceTaxii"
    )
}

BeforeAll {
    # More information about the setting can be found here:
    # https://learn.microsoft.com/en-us/rest/api/securityinsights/preview/data-connectors-check-requirements/post?tabs=HTTP#dataconnectorkind
    $TenantId = Get-AzContext | Select-Object -ExpandProperty Tenant | Select-Object -ExpandProperty Id
    $RestUri = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.OperationalInsights/workspaces/{2}/providers/Microsoft.SecurityInsights/dataConnectorsCheckRequirements?api-version=2022-12-01-preview" -f $subscriptionId, $resourceGroup, $workspaceName
}

Describe "Data Connectors Check Requirements" -Tag "DataConnectorsReqs" {
    Context "Data Connector <_>" -ForEach @( $DataConnectorsToCheck ) { 

        BeforeAll {
            $Payload = @{
                "kind"       = $_
                "properties" = @{
                    "tenantId" = $TenantId
                }
            }
            $dataConnectorsCheckRequirements = Invoke-AzRestMethod -Method POST -Uri $RestUri -Payload ( $Payload | ConvertTo-Json -Depth 3 ) | Select-Object -ExpandProperty Content | ConvertFrom-Json
        }

        It "Data Connector $_ should be authorized" {

            $dataConnectorsCheckRequirements.authorizationState | Should -Be "Valid"
        }

        It "Data Connector $_ should be licensed" {
            $dataConnectorsCheckRequirements.licenseState | Should -Be "Valid"
        }
    }
}