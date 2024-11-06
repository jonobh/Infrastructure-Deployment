This repository houses Terraform code that deploys infrastructure in Dev/Prod environments, as well as a deployment pipeline to run Terraform Plan/Apply.

Each environment should contain the following environment variables:

- AZURE_CLIENT_ID - App ID of Service Principal used by TF.
- AZURE_SUBSCRIPTION_ID - ID of subscription TF is deploying into.
- AZURE_TENANT_ID - ID of Entra tenant where TF Service Principal exists.
- TERRAFORM_PLAN_MODE - Switch to control whether Terraform is in plan or destroy mode.
- TF_STATE_CONTAINER_NAME - Name of blob container where tf state is stored.
- TF_STATE_KEY - Name of tfstate file.
- TF_STATE_RESOURCE_GROUP_NAME - Name of resource group where tf state storage account exists.
- TF_STATE_STORAGE_ACCOUNT_NAME - Name of storage account where tfstate will be placed.
