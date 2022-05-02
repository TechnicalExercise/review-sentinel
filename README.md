# Introduction

[Review Sentinel](https://github.com/TechnicalExercise/review-sentinel) is a solution for ensuring that proper reviews are being done to code being added into an organization's repositories.

Review Sentinel has 2 primary components:

1. A sample repository named "template". This repository's default branch (main) is set with the branch protection policies that you want to apply to all **new** repositories. To change the rules, just change the repo's settings for branch protection policy, and these changes will apply to the new repositories from now on.
2. A GitHub Actions workflow named [ensure-reviews](https://github.com/TechnicalExercise/review-sentinel/blob/main/.github/workflows/ensure-reviews.yml) that reads the template repo's branch protection settings and applies them to a repository when it is created. In order to ensure that new repos, empty or otherwise, can have the policies applied to them, the workflow will create a readme file as a first commit, if no other file exists. Finally, the workflow will create an **issue** in the repository, listing the rules that were set, as well as mentioning whoever created the repo.
3. An Azure Function named [BranchProtector]](<https://repoprotector.azurewebsites.net/api/BranchProtector>) that triggers the aforementioned workflow. This Azure Function has an https endpoint that gets called by a webhook (see below), whenever a new repository is created in the organization.
4. An organization-level webhook that triggers the aforementioned Azure Function whenever a repository is created within the organization.

## Setup

### Template repository

To set up the repository, simply go to the settings page, and under "Branches" go to the branch protection rules for the main branch. Edit the rules and save them to have them apply to new repositories.

### Ensure-reviews

You should not need to modify this workflow, except if you wish to add or change its behavior. See [GitHub Actions documentation](https://github.com/features/actions) for more information on hiow to do this.

### Branch Protector

In order to set up Branch Protector, you will want to clone this repository onto your workstation. You will then need to take the following steps:

#### Configure your local environment

1. Install the [Azure Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local#v2)
2. Install the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) version 2.4 or later
3. Install the [.NET Core 3.1 SDK](https://dotnet.microsoft.com/download)

#### Create supporting Azure resources for the function

1. If you haven't done this already, sign in to Azure with the following command: ```az login```.
2. You will need to create a resource group, which serves as a logical container for the function and its ancillary components. ```az group create --name <RESOURCE_GROUP> --location <REGION>```
3. Create a storage account: ```az storage account create --name <STORAGE_NAME> --location <REGION> --resource-group <RESOURCE_GROUP> --sku Standard_LRS```
4. Create the function app in Azure: ```az functionapp create --resource-group <RESOURCE_GROUP> --consumption-plan-location <REGION> --runtime powershell --functions-version 3 --name <APP_NAME> --storage-account <STORAGE_NAME>```
5. Create a KeyVault in the resource group: ```az keyvault create --resource-group <RESOURCE_GROUP> --location <REGION> --name <KEYVAULT_NAME>```
6. Go to the [Azure Portal](https://portal.azure.com) and add a GitHub personal access token (PAT) as a secret.
7. Configure the Azure Function to be able to read the PAT from the Key Vault. Follow the instructions [here](https://techmindfactory.com/Integrate-Key-Vault-Secrets-With-Azure-Functions/?msclkid=b10c6764c98d11ecb7dd634c27a8d238)

#### Deploy the funciton project to Azure

from the command line, make sure you are in the function's folder, and run ```func azure functionapp publish <APP_NAME>```. Note the url for the function.

### Create the Webhook

1. Go to the organization's settings page, and select Webhooks from the left-hand sidebar. Click **Add webhook**.
2. In **Payload URL**, paste the Azure function's URL, as menioned above.
3. Select **Content type** as application/json.
4. Under events to trigger, select the option to select individual events, and pick **Repositories**.
5. Save the webhook and leave the page.

## Using Review Sentinel

In order to activate Review Sentinel, simply create a new repository in the organization. The automation will take care of the rest. Please note that since this is a free-tier account, this will only work with public repositories.

## Attributions

In my solution I made use of the following 3rd party components:

- OctoKit's [API re action](https://github.com/marketplace/actions/github-api-request)
- Dacbd's [Create GitHub Issue action](https://github.com/marketplace/actions/create-github-issue)
- Eben Zhang's [Gist on calling GitHub's API from PowerShell](https://gist.github.com/EbenZhang/f89113ccc04f90af5e41aa739c5e086a?msclkid=e7925e84c9d711ecab4b20ebe6f95e95)
