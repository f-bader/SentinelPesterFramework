function Get-WorkspaceQueryUri {
    param (
        [Parameter(Mandatory = $true)]
        [string]$subscriptionId,

        [Parameter(Mandatory = $true)]
        [string]$resourceGroup,

        [Parameter(Mandatory = $true)]
        [string]$workspaceName
    )
    # Query the workspace to get the workspaceId
    $RestUri = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.OperationalInsights/workspaces/{2}?api-version=2021-12-01-preview" -f $subscriptionId, $resourceGroup, $workspaceName
    $WorkspaceProperties = Invoke-AzRestMethod -Method GET -Uri $RestUri | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty properties
    $WorkspaceQueryUri = "https://api.loganalytics.io/v1/workspaces/{0}/query" -f $WorkspaceProperties.customerId
    return $WorkspaceQueryUri
}

function Invoke-WorkspaceQuery {
    param (
        # KQL query to run
        [Parameter(Mandatory = $true)]
        [string]$Query,

        # Workspace Uri
        [Parameter(Mandatory = $true)]
        $WorkspaceQueryUri
    )
    $Result = Invoke-AzRestMethod -Method POST -Uri $WorkspaceQueryUri -Payload ( @{ "query" = $Query } | ConvertTo-Json )
    ($Result.Content | ConvertFrom-Json).tables.rows
}