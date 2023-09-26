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
    # Define a list of Watchlists to test
    # Each watchlist entry must have the properties name and maxAgeInDays
    $WatchListConfigObjects = @(
        @{
            "name"         = "IPAddresses"
            "maxAgeInDays" = "14"
        }
        @{
            "name"         = "HighRiskApps"
            "maxAgeInDays" = "365"
        }
    )
}

BeforeAll {
    # More information about the API can be found here:
    # https://learn.microsoft.com/en-us/rest/api/securityinsights/stable/watchlists/list?tabs=HTTP
    # Query Watchlists
    $RestUri = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.OperationalInsights/workspaces/{2}/providers/Microsoft.SecurityInsights/watchlists?api-version=2022-01-01-preview" -f $subscriptionId, $resourceGroup, $workspaceName
    $CurrentItems = Invoke-AzRestMethod -Method GET -Uri $RestUri | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty value
}

Describe "Watchlist" -Tag "Watchlists" {

    It "Watchlist <name> is present" -ForEach $WatchListConfig {
        $WatchlistName = $name
        $Watchlist = $CurrentItems | Where-Object name -eq $WatchlistName 
        $Watchlist.name | Should -Match $WatchlistName
    }

    It "Watchlist <name> was updated in the last <maxAgeInDays> days" -ForEach $WatchListConfig {
        $WatchlistName = $name
        $Watchlist = $CurrentItems | Where-Object name -eq $WatchlistName 
        $ModifiedTime = New-TimeSpan -Start $watchList.systemData.lastModifiedAt -End (Get-Date)
        $ModifiedTime.TotalDays | Should -BeLessOrEqual $maxAgeInDays
    }
}