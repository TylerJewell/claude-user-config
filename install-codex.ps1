param(
  [string]$ProjectPath = "",
  [switch]$ForceProjectFiles,
  [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CodexSource = Join-Path $RepoDir "codex"
$CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }

Write-Host "Installing Codex user config from $RepoDir"
Write-Host ""

if (-not $WhatIf) {
  New-Item -ItemType Directory -Force -Path $CodexHome | Out-Null
}

$ConfigSource = Join-Path $CodexSource "config.toml.template"
$ConfigTarget = Join-Path $CodexHome "config.toml"
$BeginMarker = "# BEGIN claude-user-config codex managed"
$EndMarker = "# END claude-user-config codex managed"

function Remove-TomlTable {
  param(
    [string]$Content,
    [string]$TableName
  )

  $pattern = "(?ms)^\[$([regex]::Escape($TableName))\]\r?\n.*?(?=^\[|\z)"
  return [regex]::Replace($Content, $pattern, "")
}

function Remove-ManagedBlock {
  param([string]$Content)

  $pattern = "(?ms)^$([regex]::Escape($BeginMarker))\r?\n.*?^$([regex]::Escape($EndMarker))\r?\n?"
  return [regex]::Replace($Content, $pattern, "")
}

$managedConfig = (Get-Content -Raw -LiteralPath $ConfigSource).Trim()
$existingConfig = if (Test-Path $ConfigTarget) {
  Get-Content -Raw -LiteralPath $ConfigTarget
} else {
  ""
}

$nextConfig = Remove-ManagedBlock $existingConfig
$nextConfig = Remove-TomlTable $nextConfig "windows"
$nextConfig = Remove-TomlTable $nextConfig "mcp_servers.akka"
$nextConfig = $nextConfig.TrimEnd()
if ($nextConfig.Length -gt 0) {
  $nextConfig += "`n`n"
}
$nextConfig += "$BeginMarker`n$managedConfig`n$EndMarker`n"

if ($nextConfig -ne $existingConfig) {
  if ($WhatIf) {
    Write-Host "Would update $ConfigTarget"
  } else {
    if (Test-Path $ConfigTarget) {
      $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
      $backup = "$ConfigTarget.bak.$stamp"
      Copy-Item -LiteralPath $ConfigTarget -Destination $backup
      Write-Host "Backed up existing config.toml to $backup"
    }
    Set-Content -LiteralPath $ConfigTarget -Value $nextConfig -NoNewline -Encoding utf8
    Write-Host "Installed managed Codex config block to $ConfigTarget"
  }
} else {
  Write-Host "config.toml already contains the managed Codex config"
}

function Install-ProjectTemplate {
  param(
    [string]$Source,
    [string]$Destination,
    [string]$Label
  )

  if ((Test-Path $Destination) -and -not $ForceProjectFiles) {
    Write-Host "Skipped $Label because $Destination already exists. Use -ForceProjectFiles to overwrite."
    return
  }

  if ($WhatIf) {
    Write-Host "Would install $Label to $Destination"
    return
  }

  Copy-Item -LiteralPath $Source -Destination $Destination
  Write-Host "Installed $Label to $Destination"
}

if ($ProjectPath -and $ProjectPath.Trim().Length -gt 0) {
  $ResolvedProject = Resolve-Path -LiteralPath $ProjectPath
  Install-ProjectTemplate `
    -Source (Join-Path $CodexSource "mcp.json.template") `
    -Destination (Join-Path $ResolvedProject ".mcp.json") `
    -Label "project .mcp.json"
  Install-ProjectTemplate `
    -Source (Join-Path $CodexSource "AGENTS.md.template") `
    -Destination (Join-Path $ResolvedProject "AGENTS.md") `
    -Label "project AGENTS.md"
}

Write-Host ""
if ($WhatIf) {
  Write-Host "Dry run complete. No files were changed."
} else {
  Write-Host "Done. Restart Codex for user config changes to take effect."
}
Write-Host "Secrets and local runtime files were not copied."
