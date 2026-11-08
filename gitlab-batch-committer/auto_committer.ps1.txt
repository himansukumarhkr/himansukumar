# ==============================================================================
# GitLab Batch Committer (Universal Enterprise VDI & Public GitLab Compatible)
# Commit Messages Managed via phrases.toon
# ==============================================================================

# Universal TLS & SSL bypass that does NOT break the .NET SChannel handshake
try {
    if (-not ([System.Management.Automation.PSTypeName]'TrustAllCertsPolicy').Type) {
        Add-Type @'
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int problem) {
        return true;
    }
}
'@
    }
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
} catch {}

# Enable TLS 1.2, TLS 1.1, and TLS 1.0
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls

$ScriptDir  = $PSScriptRoot
$StateFile  = Join-Path $ScriptDir "state.json"
$SourceFile = Join-Path $ScriptDir "source.txt"
$ToonFile   = Join-Path $ScriptDir "phrases.toon"

# Ensure source.txt exists with sample Java code if not present
if (-not (Test-Path $SourceFile)) {
    $sampleContent = @"
public class DynamicData {
    public static void main(String[] args) {
        System.out.println("Processing dynamic records...");
    }
}
"@
    Set-Content -Path $SourceFile -Value $sampleContent -Encoding UTF8
    Write-Host "[INFO] source.txt was missing. Created sample source file." -ForegroundColor Yellow
}

# Ensure phrases.toon exists with default template if not present
if (-not (Test-Path $ToonFile)) {
    $sampleToon = @"
# ==============================================================================
# Commit Message Configuration (.toon format)
# Human-friendly format: No quotes, no commas, no brackets needed!
# Lines starting with '#' are comments.
# ==============================================================================

[COMPULSORY]
# Enter your mandatory Jira ID, tag, or prefix below (leave empty if none):
BVB-24160

[PHRASES]
# Enter your custom phrases below (one phrase per line).
# Exactly 1 phrase will be chosen at random for each commit:
refactor core logic
enhance stability and fix edge cases
optimize performance metrics
update execution handlers and fixtures
add validation for dynamic payload
clean up redundant helper methods
"@
    Set-Content -Path $ToonFile -Value $sampleToon -Encoding UTF8
    Write-Host "[INFO] phrases.toon created. You can edit phrases anytime in this file." -ForegroundColor Yellow
}

# Lightweight built-in parser for .toon format (no external modules needed)
function Read-ToonConfig($path) {
    if (-not (Test-Path $path)) { return $null }
    $compulsory = ""
    $phrases = [System.Collections.Generic.List[string]]::new()
    $currentSection = ""

    foreach ($line in (Get-Content -Path $path -Encoding UTF8)) {
        $trimmed = $line.Trim()
        # Skip blank lines and comments
        if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith("#")) {
            continue
        }

        # Match section headers like [COMPULSORY] and [PHRASES]
        if ($trimmed -match '^\[(.*)\]$') {
            $currentSection = $Matches[1].ToUpper()
            continue
        }

        switch ($currentSection) {
            "COMPULSORY" {
                if ([string]::IsNullOrWhiteSpace($compulsory)) {
                    $compulsory = $trimmed
                }
            }
            "PHRASES" {
                $phrases.Add($trimmed)
            }
            default {
                $phrases.Add($trimmed)
            }
        }
    }

    return @{
        Compulsory = $compulsory
        Phrases    = @($phrases)
    }
}

# Generates a commit message from .toon data: Compulsory + 1 Random Phrase
function Get-FormattedCommitMessage($toonData) {
    $phrases = $toonData.Phrases
    $selectedPhrase = if ($phrases -and $phrases.Count -gt 0) {
        $phrases | Get-Random
    } else {
        "update component definitions"
    }

    if (-not [string]::IsNullOrWhiteSpace($toonData.Compulsory)) {
        $comp = $toonData.Compulsory.Trim()
        if ($comp -match '[:\- \]\)]\s*$') {
            return "$comp $selectedPhrase"
        } else {
            return "$comp - $selectedPhrase"
        }
    } else {
        return $selectedPhrase
    }
}

# Function to initialize state configuration interactively
function New-StateConfig {
    Write-Host "`n[SETUP] Configuring GitLab Batch Committer..." -ForegroundColor Cyan
    $pat       = Read-Host "Enter your GitLab Personal Access Token (PAT)"
    $targetUrl = Read-Host "Enter Target GitLab File URL"
    
    $numCommits = Read-Host "Enter number of commits per run [Default: 5]"
    $numCommits = if ([string]::IsNullOrWhiteSpace($numCommits)) { 5 } else { [int]$numCommits }

    $linesPer = Read-Host "Enter lines per commit [Default: 2]"
    $linesPer = if ([string]::IsNullOrWhiteSpace($linesPer)) { 2 } else { [int]$linesPer }

    # Attempt DPAPI encryption for PAT, fall back to plain text if restricted by VDI policy
    $storedPat = $pat
    try {
        $patBytes = [System.Text.Encoding]::UTF8.GetBytes($pat)
        $encryptedBytes = [System.Security.Cryptography.ProtectedData]::Protect(
            $patBytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser
        )
        $storedPat = [Convert]::ToBase64String($encryptedBytes)
        Write-Host "[SUCCESS] PAT protected via DPAPI." -ForegroundColor Green
    } catch {
        Write-Host "[WARNING] DPAPI restricted by environment. Saving token in standard format." -ForegroundColor Yellow
    }

    $newState = [PSCustomObject]@{
        pat            = $storedPat
        targetFile     = $targetUrl
        numCommits     = [int]$numCommits
        linesPerCommit = [int]$linesPer
        cursor         = 0
    }

    $newState | ConvertTo-Json -Depth 4 | Set-Content -Path $StateFile -Encoding UTF8
    Write-Host "[SUCCESS] Configuration saved to state.json!" -ForegroundColor Green
    Write-Host "[TIP] Commit messages are managed in 'phrases.toon'. You can edit them anytime in Notepad.`n" -ForegroundColor Cyan
    return $newState
}

# Load or generate state
$state = $null
if (Test-Path $StateFile) {
    try {
        $raw = Get-Content -Path $StateFile -Raw -ErrorAction Stop
        $state = $raw | ConvertFrom-Json -ErrorAction Stop
        if (-not $state.pat -or -not $state.targetFile) {
            throw "Invalid state structure"
        }
    } catch {
        Write-Host "[WARNING] state.json is corrupted or invalid. Prompting for setup..." -ForegroundColor Yellow
        $state = New-StateConfig
    }
} else {
    Write-Host "[INFO] state.json not found. Running initial setup..." -ForegroundColor Cyan
    $state = New-StateConfig
}

# Unprotect PAT if DPAPI was used
$pat = $state.pat
try {
    $bytes = [Convert]::FromBase64String($state.pat)
    $decryptedBytes = [System.Security.Cryptography.ProtectedData]::Unprotect(
        $bytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser
    )
    $pat = [System.Text.Encoding]::UTF8.GetString($decryptedBytes)
} catch {}

# Parses URL and resolves numeric project ID to prevent .NET URI parsing bugs
function Parse-GitLabUrl($url, $token) {
    $cleanUrl = if ($url -match '^([^?]+)') { $Matches[1] } else { $url }

    if ($cleanUrl -notmatch '/-/blob/') {
        throw "Invalid GitLab URL format: Missing '/-/blob/' separator in $url"
    }

    $parts = $cleanUrl -split '/-/blob/'
    $leftPart  = $parts[0]
    $rightPart = $parts[1]

    if ($leftPart -match '^(https?://[^/]+)/(.*?)$') {
        $domain      = $Matches[1]
        $projectPath = $Matches[2]
    } else {
        throw "Could not parse domain and project path from: $leftPart"
    }

    $rightSegments = $rightPart -split '/', 2
    $branch   = $rightSegments[0]
    $filePath = $rightSegments[1]

    # Resolve project's numeric ID
    $encodedPath = [System.Uri]::EscapeDataString($projectPath)
    $lookupUri   = "$($domain)/api/v4/projects/$($encodedPath)"

    Write-Host "[INFO] Resolving numeric Project ID for '$projectPath'..." -ForegroundColor Cyan
    try {
        $proj = Invoke-RestMethod -Uri $lookupUri -Headers @{ "PRIVATE-TOKEN" = $token } -Method Get -UseDefaultCredentials -ErrorAction Stop
        $numericId = $proj.id
        Write-Host "[INFO] Successfully connected! Project: $($proj.name) (ID: $numericId)" -ForegroundColor Green
    } catch {
        throw "Failed to resolve Project ID from GitLab API. Verify PAT and permissions: $_"
    }

    $decodedFilePath = [System.Net.WebUtility]::UrlDecode($filePath)
    $fileEncoded = ($decodedFilePath -split '/' | ForEach-Object { [System.Uri]::EscapeDataString($_) }) -join '%2F'

    # Build final API URL using numeric project ID (avoids .NET URI %2F bug)
    $apiUrl = "$($domain)/api/v4/projects/$($numericId)/repository/files/$($fileEncoded)"

    return @{
        ApiUrl   = $apiUrl
        Branch   = $branch
        FilePath = $decodedFilePath
    }
}

# Resolve target info
try {
    $targetInfo = Parse-GitLabUrl $state.targetFile $pat
} catch {
    Write-Host "[WARNING] Connection check failed: $_" -ForegroundColor Yellow
    $state = New-StateConfig
    $pat = $state.pat
    try {
        $bytes = [Convert]::FromBase64String($state.pat)
        $decryptedBytes = [System.Security.Cryptography.ProtectedData]::Unprotect(
            $bytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser
        )
        $pat = [System.Text.Encoding]::UTF8.GetString($decryptedBytes)
    } catch {}
    $targetInfo = Parse-GitLabUrl $state.targetFile $pat
}

$headers = @{ "PRIVATE-TOKEN" = $pat }

# Load source content
$fullContent = Get-Content -Path $SourceFile -Raw -Encoding UTF8
$fullContent = $fullContent -replace "`r`n", "`n" -replace "`r", "`n"
$lines = $fullContent -split "`n"
$totalLines = $lines.Count
$cursor = [int]$state.cursor

# Load toon configuration for commit messages
$toonData = Read-ToonConfig -path $ToonFile
$phraseCount = if ($toonData.Phrases) { $toonData.Phrases.Count } else { 0 }
Write-Host "[INFO] Loaded phrases.toon ($phraseCount random phrases available | Compulsory: '$($toonData.Compulsory)')" -ForegroundColor Cyan
Write-Host "[INFO] Total source lines: $totalLines | Starting Cursor: $cursor" -ForegroundColor Cyan

if ($cursor -ge $totalLines) {
    Write-Host "[INFO] Cursor reached end of file. Resetting to 0." -ForegroundColor Yellow
    $cursor = 0
}

function Get-TargetFileContent($apiUrl, $branch, $headers) {
    $uri = "$($apiUrl)?ref=$($branch)"
    try {
        $res = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -UseDefaultCredentials -ErrorAction Stop
        $decoded = [System.Convert]::FromBase64String($res.content)
        return [System.Text.Encoding]::UTF8.GetString($decoded)
    } catch {
        $status = $_.Exception.Response.StatusCode.value__
        if ($status -eq 404) { return "" }
        if ($status -eq 401 -or $status -eq 403) { throw "AUTH_ERROR" }
        return $null
    }
}

function Commit-TargetFileContent($apiUrl, $branch, $content, $message, $headers) {
    $body = @{
        branch         = $branch
        commit_message = $message
        content        = $content
        encoding       = "text"
    } | ConvertTo-Json

    $checkUri = "$($apiUrl)?ref=$($branch)"
    $exists = $false
    try {
        $null = Invoke-RestMethod -Uri $checkUri -Headers $headers -Method Get -UseDefaultCredentials -ErrorAction Stop
        $exists = $true
    } catch {
        $exists = $false
    }

    $method = if ($exists) { "Put" } else { "Post" }
    try {
        $null = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method $method -Body $body -ContentType "application/json" -UseDefaultCredentials -ErrorAction Stop
        return $true
    } catch {
        Write-Error "[API ERROR] Failed to push commit ($method): $_"
        return $false
    }
}

# Fetch current target file content
Write-Host "[INFO] Fetching current content from GitLab..." -ForegroundColor Cyan
$existingContent = Get-TargetFileContent -apiUrl $targetInfo.ApiUrl -branch $targetInfo.Branch -headers $headers
if ($null -eq $existingContent) {
    $existingContent = ""
}

# Execute commit batches
$numCommits = [int]$state.numCommits
$linesPer   = [int]$state.linesPerCommit

for ($i = 1; $i -le $numCommits; $i++) {
    if ($cursor -ge $totalLines) {
        Write-Host "[INFO] Reached the end of source.txt. Ending run." -ForegroundColor Yellow
        break
    }

    $endIndex   = [Math]::Min($cursor + $linesPer, $totalLines)
    $batchLines = $lines[$cursor..($endIndex - 1)]
    $batchText  = $batchLines -join "`n"

    Write-Host "`n----------------------------------------" -ForegroundColor DarkGray
    Write-Host "Batch Step $i of $numCommits (Lines: $($cursor + 1) to $endIndex):" -ForegroundColor Magenta
    foreach ($line in $batchLines) {
        Write-Host "  > $line" -ForegroundColor Gray
    }

    if ([string]::IsNullOrEmpty($existingContent)) {
        $existingContent = $batchText
    } else {
        $existingContent += "`n" + $batchText
    }

    # Generate commit message from .toon format
    $msg = Get-FormattedCommitMessage -toonData $toonData

    Write-Host "Commit Message: '$msg'" -ForegroundColor DarkCyan
    $ok = Commit-TargetFileContent -apiUrl $targetInfo.ApiUrl -branch $targetInfo.Branch -content $existingContent -message $msg -headers $headers

    if ($ok) {
        # Advance cursor and save state ONLY upon verified success
        $cursor = $endIndex
        $state.cursor = $cursor
        $state | ConvertTo-Json -Depth 4 | Set-Content -Path $StateFile -Encoding UTF8
        Write-Host "[SUCCESS] Commit pushed successfully!" -ForegroundColor Green
    } else {
        Write-Host "[FAILED] Commit failed. Aborting remaining batches." -ForegroundColor Red
        break
    }
}

Write-Host "`n[DONE] Batch run completed. Current saved cursor: $cursor" -ForegroundColor Cyan
