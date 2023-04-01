# Sentinel Pester Framework

![Sentinel Pester Framework](/images/SentinelPesterFramework.png)

The Sentinel Pester Framework is a community project meant to help you use PowerShell and [Pester](https://pester.dev/) to test your [Microsoft Sentinel](https://learn.microsoft.com/azure/sentinel/) infrastructure.

You can find additional information in the related [blog Post](https://cloudbrothers.info/en/sentinel-pester-framework) on my website [cloudbrother.info](https://cloudbrothers.info/en/).

There are multiple tests for different configuration settings of Microsoft Sentinel and the Log Analytics Workspace as well as tests for thing like Analytics Rules, Automation Actions, Dataconnectors and more.

This is not meant as a ready to execute solution, but must be configured and modified for your specific environment.

If you already use a [CI/CD pipeline](https://learn.microsoft.com/en-gb/azure/sentinel/ci-cd) to deploy your Microsoft Sentinel configuration, you can use specific CI/CD related tests. Those tests are configured to use the ARM templates used to deploy the artifacts and dynamically create the necessary tests.

## Configuration

All configuration is done in the Pester test files itself with only a few exceptions.

* `workspaceName` \
  Microsoft Sentinel Workspace Id
* `resourceGroup` \
  Resource group of the Sentinel Workspace
* `subscriptionId` ß
  Subscription Id
* `CICDPathRoot` \
  The path to your Sentinel configuration files deployed via CI/CD (must be ARM templates)

```powershell
$configRunContainer = New-PesterContainer -Path "*.Tests.ps1" -Data @{
    workspaceName  = "SentinelWorkspace"
    resourceGroup  = "ResourceGroup"
    subscriptionId = "SubscriptionId"    
}
```

## Test tags

All tests are [tagged](https://pester.dev/docs/usage/tags) and this allows you to easily include or exclude certain tests.

Modify the `RunTests.ps1` accordingly.

| Tag                | Description                                                |
|--------------------|------------------------------------------------------------|
| configuration      | Sentinel Configuration: All entries                        |
| anomalies          | Sentinel Configuration: Anomalies                          |
| diagnosticsettings | Sentinel Configuration: Diagnostic Settings                |
| entityanalytics    | Sentinel Configuration: Entity Analytics                   |
| eyeson             | Sentinel Configuration: Opt-Out of Microsoft data access   |
| ueba               | Sentinel Configuration: User and Entity Behavior Analytics |
| analyticsrules     | Analytics rules                                            |
| watchlists         | Watchlists                                                 |
| dataconnector      | Test all data connector (Not recommended)                  |
| aad                | Azure Active Directory                                     |
| aadipc             | Azure AD Identity Protection                               |
| azureactivity      | Azure Audit                                                |
| DataConnectorsReqs | Data Connectors Check Requirements                         |
| dfc                | Microsoft Defender for Cloud                               |
| dns                | DNS                                                        |
| m365d              | Microsoft 365 Defender                                     |
| mda                | Microsoft Defender for Cloud Apps                          |
| mda-shadowit       | Microsoft Defender for Cloud Apps - Shadow IT Reporting    |
| o365               | Office 365                                                 |
| o365-sharepoint    | Office 365 - SharePoint and OneDrive                       |
| o365-exchange      | Office 365 - Exchange                                      |
| o365-teams         | Office 365 - SharePoint and OneDrive                       |
| securityevents     | Security Events                                            |
| sentinel           | Sentinel basic configuration                               |
| ti                 | Threat Intelligence Platforms                              |
| amadns             | Windows DNS Events via AMA                                 |
| winevents          | Windows Forwarded Events                                   |
| winfirewall        | Windows Firewall                                           |
| workspace          | Workspace basic configuration                              |

## Manual changes to test files

Some data connectors ingest data into more than one table and you might not have enabled all. In this case you must comment out the specific line in the test.

Here is an example of a modified Azure AD test file.

```powershell
Describe "Sentinel Dataconnectors" -Tag "DataConnector" {
    Describe "Azure Active Directory should be connected" -Tag "AAD" {
        It "<name> should have current data (<maxage>)" -ForEach @(
            @{ Name = "SigninLogs" ; MaxAge = "1d" }
            @{ Name = "AuditLogs" ; MaxAge = "1d" }
            # @{ Name = "AADNonInteractiveUserSignInLogs" ; MaxAge = "1d" }
            # @{ Name = "AADServicePrincipalSignInLogs" ; MaxAge = "1d" }
            # @{ Name = "AADManagedIdentitySignInLogs" ; MaxAge = "1d" }
            # @{ Name = "AADProvisioningLogs" ; MaxAge = "1d" }
            # @{ Name = "ADFSSignInLogs" ; MaxAge = "1d" }
            # @{ Name = "AADUserRiskEvents" ; MaxAge = "30d" }
            # @{ Name = "AADRiskyUsers" ; MaxAge = "30d" }
            # @{ Name = "NetworkAccessTraffic" ; MaxAge = "1d" }
            # @{ Name = "AADRiskyServicePrincipals" ; MaxAge = "30d" }
            # @{ Name = "AADServicePrincipalRiskEvents" ; MaxAge = "30d" }
        ) {
            $FirstRowReturned = Invoke-WorkspaceQuery -WorkspaceQueryUri $WorkspaceQueryUri -Query "$name | where TimeGenerated > ago($MaxAge) | summarize max(TimeGenerated)" | Select-Object -First 1
            $FirstRowReturned | Should -Not -BeNullOrEmpty
        }
    }
}
```

In this environment only `SigninLogs` and `AuditLogs` logs are forwarded to Microsoft Sentinel, all other tables are excluded from the test.

Another example would be if you don't use Microsoft Defender for Identity and don't want to use ActiveDirectory as a source for UEBA. Just remove `"ActiveDirectory"` from the test file.

```powershell
It "EntityAnalytics source <_> is enabled" -ForEach "AzureActiveDirectory" -Tag "EntityAnalytics" {
    $SentinelSettings | Where-Object { $_.name -eq "EntityAnalytics" } | Select-Object -ExpandProperty properties | Select-Object -ExpandProperty entityProviders | Should -Contain $_
}
```

### Run Pester

There are two example files provided to run Pester. `RunTest.ps1` and `RunTest-CICD.ps1`.

Those Pester configurations are used to specify the tags that should be used and you can also modify other settings of the Pester test run. For more information consult the official [Pester documentation](https://pester.dev/docs/commands/New-PesterConfiguration).

```powershell
Install-Module Az.Accounts -Force

Connect-AzAccount -DeviceCode
Set-AzContext -SubscriptionId $subscriptionId

$configRunContainer = New-PesterContainer -Path "*.Tests.ps1" -Data @{
    # Define your environment variables here
    workspaceName  = "SentinelWorkspaceName"
    resourceGroup  = "resourceGroup"
    subscriptionId = "SubscriptionId"
}

$config = New-PesterConfiguration -Hashtable @{
    Filter     = @{
        # Use the filter configuration to only specify the tests
        # This way you can easily remove e.g. specific dataconnectors from the test without mofiying the test itself
        # You will always have to modify the tests.ps1 file if you would like to remove specific tables it change the target configuration
        Tag = "Configuration", "AnalyticsRules", "Watchlists", "AAD", "AADIPC", "AzureActivity", "DfC", "O365"
    }
    TestResult = @{ Enabled = $true }
    Run        = @{
        Exit      = $true
        Container = $configRunContainer
    }
    Output     = @{ Verbosity = 'Detailed' }
}
Invoke-Pester -Configuration $config
```

## Currently available tests

| Test                                                                            | Regular            | CI/CD*                        |
|---------------------------------------------------------------------------------|--------------------|-------------------------------|
| Analytics rules should not be in state "AUTO DISABLED"                          | :white_check_mark: | :white_check_mark:            |
| Analytics rule <_> is present                                                   | :white_check_mark: | :white_check_mark:            |
| Analytics rule <id> name is set to <name>                                       | :x:                | :white_check_mark:            |
| Analytics rule <_> is enabled                                                   | :white_check_mark: | :white_check_mark:            |
| Automation rule <id> is present                                                 | :x:                | :white_check_mark:            |
| Automation rule <id> order is set to <order>                                    | :x:                | :white_check_mark:            |
| Automation rule <id> is <enabled>                                               | :x:                | :white_check_mark:            |
| UEBA Source <_> is enabled                                                      | :white_check_mark: | :negative_squared_cross_mark: |
| EntityAnalytics source <_> is enabled                                           | :white_check_mark: | :negative_squared_cross_mark: |
| Anomalies is enabled                                                            | :white_check_mark: | :negative_squared_cross_mark: |
| Microsoft data access is enabled (EyesOn)                                       | :white_check_mark: | :negative_squared_cross_mark: |
| Diagnostic settings are send to the same Log Analytics workspace                | :white_check_mark: | :negative_squared_cross_mark: |
| All diagnostic settings are enabled                                             | :white_check_mark: | :negative_squared_cross_mark: |
| SentinelHealth should have current data (1d)                                    | :white_check_mark: | :negative_squared_cross_mark: |
| Workspace should be located in West Europe                                      | :white_check_mark: | :negative_squared_cross_mark: |
| Workspace retention is set to 90 days                                           | :white_check_mark: | :negative_squared_cross_mark: |
| Workspace capping should be disabled                                            | :white_check_mark: | :negative_squared_cross_mark: |
| Workspace access control mode should be "Use resource or workspace permissions" | :white_check_mark: | :negative_squared_cross_mark: |
| Workspace sku should be "PerGB2018"                                             | :white_check_mark: | :negative_squared_cross_mark: |
| Workspace should not have a capacity reservation                                | :white_check_mark: | :negative_squared_cross_mark: |
| Workspace should not purge data immediately                                     | :white_check_mark: | :negative_squared_cross_mark: |
| Workspace should have a cannot-delete lock                                      | :white_check_mark: | :negative_squared_cross_mark: |

* If a specific CI/CD tests would not make sense, then it's marked as :negative_squared_cross_mark:

For data connectors the tests are not listed here but the basic test "<tablename> should have current data (1d)" checks that there is at least one datapoint ingested within the last 24 hours.

For tables with more than one datasource the test is named "<tablename> (<product>) should have current data (1d)".

For data connectors with more than one table, the tables are defined as a hashtable as part of the tests `ForEach`.

```powershell
-ForEach @(
    @{ Name = "SigninLogs" ; MaxAge = "1d" }
    @{ Name = "AuditLogs" ; MaxAge = "1d" }
}
```

The timeframe can be modified to your needs within the test file.
