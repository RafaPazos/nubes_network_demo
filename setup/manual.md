# Setup a terraform project with Github Actions

## login

az login

gh auth login

## create state

Set environment variables - those are the main variables you might want to configure.

Set-Variable -Name "RESOURCE_GROUP_NAME" -Value "rg-terraform-001"
Set-Variable -Name "LOCATION" -Value "westeurope"
Set-Variable -Name "TF_STORAGE_ACCOUNT" -Value "stinfraascode"
Set-Variable -Name "CONTAINER_NAME" -Value "tfstate"

az group create --name $RESOURCE_GROUP_NAME --location $LOCATION -o none

az storage account create --resource-group $RESOURCE_GROUP_NAME --name $TF_STORAGE_ACCOUNT --sku Standard_LRS --allow-blob-public-access false --encryption-services blob -o none

$ACCOUNT_KEY=(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $TF_STORAGE_ACCOUNT --query '[0].value' -o tsv)

az storage container create --name $CONTAINER_NAME --account-name $TF_STORAGE_ACCOUNT --account-key $ACCOUNT_KEY -o none

## create service principal for the connection to github

$SUBSCRIPTION_ID=(az account show --query id --output tsv --only-show-errors)
$SERVICE_PRINCIPAL=(az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/$SUBSCRIPTION_ID" --sdk-auth --only-show-errors)

gh secret set AZURE_CREDENTIALS -b"$SERVICE_PRINCIPAL" 
gh secret set TF_STORAGE_ACCOUNT -b"$TF_STORAGE_ACCOUNT"