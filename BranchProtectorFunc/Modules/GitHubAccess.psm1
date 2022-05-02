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
    
function GetRestfulErrorResponse($exception) {
    $ret = ""
    if ($exception.Exception -and $exception.Exception.Response) {
        $result = $exception.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($result)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $ret = $reader.ReadToEnd()
        $reader.Close()
    }
    if ($ret -eq $null -or $ret.Trim() -eq "") {
        $ret = $exception.ToString()
    }
    return $ret
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
    
function Get-BranchProtection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][String]$Username,
        [Parameter(Mandatory = $true)][String]$Token,
        [Parameter(Mandatory = $true)][String]$Owner,
        [Parameter(Mandatory = $true)][String]$Repo,
        [Parameter(Mandatory = $true)][String]$Branch
    )
    
    # try {
        Write-Host "Before api call"
        $headers = CreateGitHubRequestHeaders -username $Username -token $Token
        Invoke-WebRequest -Method Get `
        -Uri "https://api.github.com/repos/$Owner/$Repo/branches/$Branch/protection" `
        -Headers $headers
        
        Write-Host "after api call"
    # }
    # catch {
    #     $resp = (GetRestfulErrorResponse $_)
    #     Write-Error $resp
    #     throw
    # }
}

function Set-BranchProtection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][String]$Username,
        [Parameter(Mandatory = $true)][String]$Token,
        [Parameter(Mandatory = $true)][String]$Owner,
        [Parameter(Mandatory = $true)][String]$Repo,
        [Parameter(Mandatory = $true)][String]$Branch,
        [Parameter(Mandatory = $true)][String]$ProtectionTemplate
    )
    
    # try {
        Write-Host "Before api call"
        $protection = $ProtectionTemplate | ConvertFrom-Json

        $headers = CreateGitHubRequestHeaders -username $Username -token $Token
        $body = @{
            required_status_checks = $protection.required_status_checks
            restrictions = $protection.restrictions
            required_pull_request_reviews = $protection.required_pull_request_reviews
            enforce_admins = $protection.enforce_admins.enabled
            required_linear_history = $protection.required_linear_history.enabled
            allow_force_pushes = $protection.allow_force_pushes.enabled
            allow_deletions = $protection.allow_deletions.enabled
            required_conversation_resolution = $protection.required_conversation_resolution.enabled
        } | ConvertTo-Json

        Write-Host "Body: $body"

        Invoke-WebRequest -Method Put `
        -Uri "https://api.github.com/repos/$Owner/$Repo/branches/$Branch/protection" `
        -Headers $headers `
        -Body $body
        
        Write-Host "after api call"
    # }
    # catch {
    #     $resp = (GetRestfulErrorResponse $_)
    #     Write-Error $resp
    #     throw
    # }
}

function Set-DefaultBranchContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][String]$Username,
        [Parameter(Mandatory = $true)][String]$Token,
        [Parameter(Mandatory = $true)][String]$Owner,
        [Parameter(Mandatory = $true)][String]$Repo
    )

    git clone "https://$Username\:$Token@github.com/$Owner/$Repo.git"
    Push-Location
    Set-Location $Repo
    if (-not(Test-Path -Path .\README.md)) {
        echo "# Welcome to the $Repo repository" > .\README.md
        
        git add .\README.md
        git commit -m "Readme file added by Repo-Protector"
        git push
    }
    Pop-Location
    Remove-Item $Repo -Force -Recurse
}