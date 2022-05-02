using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

Import-Module .\Modules\GitHubAccess.psm1

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed the request."

$secret = [System.Environment]::GetEnvironmentVariable("ACCESS_TOKEN", [System.EnvironmentVariableTarget]::Process)

if ($TriggerMetadata) {
    # $client_payload = $TriggerMetadata | ConvertFrom-Json -Depth 5
    Write-Host "Action: $($TriggerMetadata.action)"

    if ($TriggerMetadata.action -eq "created") {
        $repo = $TriggerMetadata.repository.name
        $owner = $TriggerMetadata.repository.owner.login
        $branch = $TriggerMetadata.repository.default_branch
        $senderLogin = $TriggerMetadata.sender.login

        Write-Host "Dispatching ensure-reviews workflow"
        Start-RepoProtectionWorkflow -Username $senderLogin -Token $secret -Owner $owner -Repo $repo -Branch $branch


        # Write-Host "Setting policy for $owner/$repo : $branch"

        # $protectionTemplate = (Get-BranchProtection -Username $senderLogin -Token $secret -Owner $owner -Repo Template -Branch main)

        # Write-Host "Branch protection template: $protectionTemplate"

        # Set-DefaultBranchContent -Username $senderLogin -Token $secret -Owner $owner -Repo $repo

        # $responseCode = Set-BranchProtection -Username $senderLogin -Token $secret -Owner $owner -Repo Template -Branch main -ProtectionTemplate $protectionTemplate
    }
}





# Interact with query parameters or the body of the request.
$name = $Request.Query.Name
if (-not $name) {
    $name = $Request.Body.Name
}

$body = "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response."

if ($name) {
    $body = "Hello, $name. This HTTP triggered function executed successfully."
}
Write-Host $body

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $body
    })
