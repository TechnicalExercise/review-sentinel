function CreateGitHubRequestHeaders([string]$username, [string]$token) {
    Write-Host "creating header"

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $token)))
    $headers = @{
        Accept = "application/vnd.github.v3+json"
        Authorization = "Basic $base64AuthInfo" 
    }
    return $headers
}

function Start-RepoProtectionWorkflow {
    param (
        [Parameter(Mandatory = $true)][String]$Username,
        [Parameter(Mandatory = $true)][String]$Token,
        [Parameter(Mandatory = $true)][String]$Owner,
        [Parameter(Mandatory = $true)][String]$Repo,
        [Parameter(Mandatory = $true)][String]$Branch
    )
    
    Write-Host "Before api call"
    $headers = CreateGitHubRequestHeaders -username $Username -token $Token
    $uri = "https://api.github.com/repos/$Owner/review-sentinel/dispatches"
    Write-Host "Uri: $uri"

    $body = @{
        event_type = "created"
        client_payload = @{
            owner = $Owner
            repo = $Repo
            branch = $Branch
        } # | ConvertTo-Json -Compress
    } | ConvertTo-Json -Compress

    Write-Host "Body: $body"

    Invoke-WebRequest -Method Post `
        -Uri $uri `
        -Headers $headers `
        -Body $body

    Write-Host "After call"
}