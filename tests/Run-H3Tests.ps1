#requires -Version 5.1
[CmdletBinding()]
param([string]$PesterManifest = '', [ValidatePattern('^[a-z0-9_-]+$')][string]$Label = 'local')
$ErrorActionPreference = 'Stop'
if ($PesterManifest) { Import-Module $PesterManifest -MinimumVersion 5.0 -Force }
else { Import-Module Pester -MinimumVersion 5.0 -Force }
$start = [datetime]::UtcNow
$config = New-PesterConfiguration
$config.Run.Path = Join-Path $PSScriptRoot 'H3.Tests.ps1'
$config.Run.PassThru = $true
$config.TestRegistry.Enabled = $false
$config.TestDrive.Enabled = $false
$config.Output.Verbosity = 'Detailed'
$r = Invoke-Pester -Configuration $config
$report = [ordered]@{
    schema='h3.tests.v1'; synthetic=$true; engine=$PSVersionTable.PSVersion.ToString()
    edition=$PSVersionTable.PSEdition; pester=(Get-Module Pester).Version.ToString()
    startedUtc=$start.ToString('o'); finishedUtc=[datetime]::UtcNow.ToString('o')
    passed=$r.PassedCount; failed=$r.FailedCount; skipped=$r.SkippedCount; total=$r.TotalCount
    cases=@($r.Tests | ForEach-Object { @{name=$_.Name; result=[string]$_.Result} })
}
$out = Join-Path (Split-Path $PSScriptRoot -Parent) 'work-private/h3-results'
[IO.Directory]::CreateDirectory($out) | Out-Null
$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $out ($Label + '.json')) -Encoding UTF8
if ($r.FailedCount -gt 0 -or $r.PassedCount -ne $r.TotalCount) { exit 1 }
exit 0
