# Pre-requisite - Install-Module -Name Az -AllowClobber -Scope CurrentUser

# Prompt for Azure login with device authentication
Connect-AzAccount

# Input Parameters
$subscriptionList = @("Dev", "Prod") # List of subscription names (should match respective environments in Github)
$githubAccount = "jonobh" # Your GitHub account name
$repos = @("Infrastructure-Deployment", "Net-Deployment", "JavaSpring-Deployment") # List of repositories (Infra and App)

# Loop through each subscription name to create required resources for Terraform pipeline to run
foreach ($subscriptionName in $subscriptionList) {

    # Get the subscription ID
    $subscription = Get-AzSubscription | Where-Object { $_.Name -eq $subscriptionName }

    # Create a service principal
    $sp = New-AzADServicePrincipal -DisplayName "$subscriptionName-SP"
    $spobject = Get-AzADApplication -DisplayName "$subscriptionName-SP"

    # Assign Owner role to the service principal on the new subscription
    New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName "Owner" -Scope "/subscriptions/$($subscription.Id)"

    # Setup federated credentials for Github repos to request OIDC tokens and authenticate with Azure
    foreach ($repo in $repos) {
            $federatedIdentityName = "$($repo)-$($githubAccount)"

            # Federated identity for the main branch
            $mainFederatedCredential = New-AzADAppFederatedCredential -ApplicationObjectId $spobject.Id `
                -Issuer "https://token.actions.githubusercontent.com" `
                -Audience "api://AzureADTokenExchange" `
                -Subject "repo:$($githubAccount)/$($repo):ref:refs/heads/Main" `
                -Name "$($federatedIdentityName)-Main" `
                -Description "Federated identity for GitHub Actions for $($repo) (Main Branch)" `

            # Federated identity for pull requests targeting the main branch
            $prFederatedCredentialMain = New-AzADAppFederatedCredential -ApplicationObjectId $spobject.Id `
                -Issuer "https://token.actions.githubusercontent.com" `
                -Audience "api://AzureADTokenExchange" `
                -Subject "repo:$($githubAccount)/$($repo):pull_request" `
                -Name "$($federatedIdentityName)-PR-Main" `
                -Description "Federated identity for PRs targeting the main branch for $($repo)" `

            # Federated identity from specified environments
            $prFederatedCredentialOther = New-AzADAppFederatedCredential -ApplicationObjectId $spobject.Id `
                -Issuer "https://token.actions.githubusercontent.com" `
                -Audience "api://AzureADTokenExchange" `
                -Subject "repo:$($githubAccount)/$($repo):environment:$($subscriptionName)" `
                -Name "$($federatedIdentityName)-PR-Environment" `
                -Description "Federated identity for PRs for $($repo) in $($subscriptionName)" `
        }

    # Create a resource group and storage account in each subscription to house Terraform state
    Set-AzContext -SubscriptionId $subscription.Id
    $resourceGroup = New-AzResourceGroup -Name "$($subscriptionName)-terraform-rg".ToLower() -Location "westeurope"

    $storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroup.ResourceGroupName `
    -AccountName "$($subscriptionName)tfstatejvk".ToLower() `
    -Location "westeurope" `
    -SkuName Standard_LRS `
    -Kind StorageV2

    $storageContext = $storageAccount.Context

    New-AzStorageContainer -Name "tfstate" -Context $storageContext

    # Assign Storage Blob Data Contributor role to the service principal on the new storage account
    New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName "Storage Blob Data Contributor" -Scope "/subscriptions/$($subscription.Id)/resourceGroups/$($resourceGroup.ResourceGroupName)/providers/Microsoft.Storage/storageAccounts/$($storageAccount.StorageAccountName)"

    # Output details
    Write-Host "Terraform Pipeline vars/secrets for '$subscriptionName':"
    Write-Host "AZURE_CLIENT_ID: $($sp.AppId)"
    Write-Host "AZURE_TENANT_ID: $($subscription.TenantId)"
    Write-Host "AZURE_SUBSCRIPTION_ID: $($subscription.Id)"
    Write-Host "TF_STATE_STORAGE_ACCOUNT_NAME: $($subscriptionName)tfstatejvk".ToLower()
    Write-Host "TF_STATE_RESOURCE_GROUP_NAME: $($subscriptionName)-terraform-rg".ToLower()
    Write-Host "TF_STATE_CONTAINER_NAME: tfstate"
    Write-Host "TF_STATE_KEY: $($subscriptionName).tfstate".ToLower()

    Write-Host "-----------------------------------"

}
