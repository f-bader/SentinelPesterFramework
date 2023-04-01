#region Install required modules
if ( -not ( Get-Module -ListAvailable Az.Accounts ) ) { 
    Install-Module Az.Accounts -Force
}
#endregion

#region Switch to correct subscription
Set-AzContext -SubscriptionId $Env:subscriptionId | Out-Null
#endregion

<#
 When connecting a GitHub or Azure DevOps repository to Microsoft Sentinel, the artifacts are organized in folders named
 \AnalyticsRule
 \AutomationRule
 \HuntingQuery
 \Parser
 \Playbook
 \Workbook

 Use, where available, the tests with the tag suffix "-CICD" instead of the normal tests.
 Those tests will automatically parse the ARM template files in your configuration root and Pester uses this information 
 to dynamically create the tests. This way you can easily add new configuration without having to modify the tests.
#>

$configRunContainer = @(
    # Add the CI/CD configuration path as parameter to all CI/CD tests
    New-PesterContainer -Path "*.Tests.ps1" -Data @{
        workspaceName  = $Env:workspaceName
        resourceGroup  = $Env:resourceGroupName
        subscriptionId = $Env:subscriptionId
        # This is the path to the root of your Sentinel configuration files
        CICDPathRoot   = $PWD
    }
)

$config = New-PesterConfiguration -Hashtable @{
    Filter     = @{
        # Use the filter configuration to only specify the tests
        # This way you can easily remove e.g. specific dataconnectors from the test without mofiying the test itself
        # You will always have to modify the tests.ps1 file if you would like to remove specific tables it change the target configuration
        Tag = "AutomationRules-CICD", "AnalyticsRules-CICD", "Configuration"
    }
    TestResult = @{ Enabled = $true }
    Run        = @{ 
        Exit      = $false
        Container = $configRunContainer
    }
    Output     = @{ Verbosity = 'Detailed' }
}
Invoke-Pester -Configuration $config
