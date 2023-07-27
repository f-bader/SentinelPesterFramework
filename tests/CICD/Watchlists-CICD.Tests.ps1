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
        Write-Host "List all wachlists in $AnalyticsRulePath"
        if ( Test-Path $AnalyticsRulePath ) {
            #region
            $UsedWatchlistsObject = Select-String "_GetWatchlist\('.*?'\)" -Path "$AnalyticsRulePath/*"
            $UsedWatchlistsObject | % {
                Write-Host $_
            }
            $UsedWatchlists = @( $UsedWatchlistsObject.Matches.Value -replace "_GetWatchlist\('(.*?)'\)", '$1' | Select-Object -Unique )
            if ( [string]::IsNullOrWhiteSpace($UsedWatchlists) ) {
                $UsedWatchlists = $null
            }
            #endregion
        }
    }
}

BeforeAll {
    # More information about the API can be found here:
    # https://learn.microsoft.com/en-us/rest/api/securityinsights/preview/watchlist-items/list
    # Query deployed watchlists
    $RestUri = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.OperationalInsights/workspaces/{2}/providers/Microsoft.SecurityInsights/watchlists?api-version=2022-01-01-preview" -f $subscriptionId, $resourceGroup, $workspaceName
    $CurrentItems = Invoke-AzRestMethod -Method GET -Uri $RestUri | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty value
}

Describe "Watchlists" -Tag "Watchlists-CICD" -ForEach $UsedWatchlists {

    It "Watchlist <_> used by Analytics Rules is deployed" {
        $Item = $CurrentItems | Where-Object { $_.name -match $_ }
        $Item.name | Should -Be $_
    }

}
