#requires -Version 5.1
[CmdletBinding(SupportsShouldProcess = $true)]
param([ValidatePattern('^[a-zA-Z0-9_-]{1,60}$')][string]$Name = ('case-' + [guid]::NewGuid().ToString('N')))
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$root = Join-Path $repo ('work-private/h3-sandboxes/' + $Name)
if (Test-Path -LiteralPath $root) { throw 'Fixture root must be new.' }
# Verify ancestors before writing. The fixture generator must not follow a junction.
$ancestor = [IO.DirectoryInfo]$root
while ($null -ne $ancestor) {
    if ($ancestor.Exists -and ($ancestor.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Reparse ancestor.' }
    $ancestor = $ancestor.Parent
}
if ($PSCmdlet.ShouldProcess('new synthetic sandbox', 'Create fixture files')) {
    foreach ($dir in @('', 'temp', 'logs', 'dumps', 'audit')) {
        [IO.Directory]::CreateDirectory((Join-Path $root $dir)) | Out-Null
    }
    [IO.File]::WriteAllText((Join-Path $root '.synthetic-maintenance-sandbox'), 'H3_SYNTHETIC_ONLY_V1')
    [IO.File]::WriteAllText((Join-Path $root '.maintenance.lock'), '')
    $routes = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'routes.synthetic.json') -Raw | ConvertFrom-Json
    $routes.managedRoot = 'work-private/h3-sandboxes/' + $Name
    $routes | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $root 'maintenance.routes.json') -Encoding UTF8
    $scenario = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'scenario.json') -Raw | ConvertFrom-Json
    $disposable = @()
    foreach ($file in $scenario.files) {
        $path = Join-Path $root $file.path
        [IO.File]::WriteAllText($path, ('SYNTHETIC H3 FIXTURE: ' + $file.path))
        [IO.File]::SetLastWriteTimeUtc($path, [datetime]::UtcNow.AddDays(-$file.ageDays))
        if ($file.disposable) { $disposable += [IO.Path]::GetFileName($path) }
    }
    @{schema='h3.disposable.v1'; hold=$false; files=$disposable} | ConvertTo-Json |
        Set-Content -LiteralPath (Join-Path $root 'disposable.json') -Encoding UTF8
    $root
}
