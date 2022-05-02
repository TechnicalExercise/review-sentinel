[CmdletBinding()]
param (
    $rg = "RepoProtector-RG"
    $storage = "repoprot0425"
    $region = "eastus"
    $app = "RepoProtector"
    [Switch]$CreateResources
)

# Setup
if ($CreateResources.IsPresent) {
    az login
    az group create --name RepoProtector-RG --location eastus
    az storage account create --name $storage --location $region --resource-group $rg --sku Standard_LRS
    az functionapp create --resource-group $rg --consumption-plan-location $region --runtime powershell --functions-version 4 --name $app --storage-account $storage
}

# Publish
func azure functionapp publish $app