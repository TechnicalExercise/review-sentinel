using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

Import-Module .\Modules\GitHubAccess.psm1

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed the request."

$secret = [System.Environment]::GetEnvironmentVariable("ACCESS_TOKEN", [System.EnvironmentVariableTarget]::Process)

if ($TriggerMetadata) {
    Write-Host "Action: $($TriggerMetadata.action)"

    if ($TriggerMetadata.action -eq "created") {
        $repo = $TriggerMetadata.repository.name
        $owner = $TriggerMetadata.repository.owner.login
        $branch = $TriggerMetadata.repository.default_branch
        $senderLogin = $TriggerMetadata.sender.login

        Write-Host "Dispatching ensure-reviews workflow"
        Start-RepoProtectionWorkflow -Username $senderLogin -Token $secret -Owner $owner -Repo $repo -Branch $branch
    }
}

$body = "This HTTP triggered function executed successfully."
Write-Host $body

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $body
    })
