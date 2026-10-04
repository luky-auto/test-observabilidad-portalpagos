#requires -Version 5.1
Set-StrictMode -Version Latest

function Assert-PlainPath {
    param([string]$Path)
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    while ($null -ne $item) {
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw 'Reparse points are not allowed.'
        }
        if ($item -is [IO.DirectoryInfo]) { $item = $item.Parent }
        else { $item = $item.Directory }
    }
}

function Remove-MaintenanceFile {
    param([string]$LiteralPath)
    # Only called after the caller's ShouldProcess, path and manifest checks.
    Remove-Item -LiteralPath $LiteralPath -ErrorAction Stop -Confirm:$false
}

function Get-AuthorizedRoot {
    param([string]$ConfigurationPath, [string]$RequestedRoot)
    if ($ConfigurationPath -match '^[\\/]{2}|[*?\[\]]|::|(^|[\\/])\.\.([\\/]|$)') { throw 'Unsafe configuration path.' }
    $configFullPath = [IO.Path]::GetFullPath($ConfigurationPath)
    $configDrive = New-Object IO.DriveInfo ([IO.Path]::GetPathRoot($configFullPath))
    if ($configDrive.DriveType -ne [IO.DriveType]::Fixed) { throw 'Configuration must be on a local fixed volume.' }
    Assert-PlainPath $ConfigurationPath
    $configFile = Get-Item -LiteralPath $ConfigurationPath
    if ($configFile.PSIsContainer -or $configFile.Length -gt 16384) { throw 'Invalid configuration file.' }
    $json = [IO.File]::ReadAllText($configFile.FullName)
    $policy = $json | ConvertFrom-Json
    # Closed schema, validated without PS7-only Test-Json or external dependencies.
    $expected = @('schema','mode','enabled','computerName','managedRoot','laboratoryBoundary','markerName','markerValue')
    $keys = @([regex]::Matches($json, '"([A-Za-z]+)"\s*:') | ForEach-Object { $_.Groups[1].Value })
    if ($keys.Count -ne $expected.Count -or @($keys | Select-Object -Unique).Count -ne $expected.Count) { throw 'Duplicate or invalid route keys.' }
    if ($policy -isnot [pscustomobject] -or @($policy.PSObject.Properties).Count -ne $expected.Count) { throw 'Invalid route schema.' }
    foreach ($property in $policy.PSObject.Properties) {
        if ($property.Name -cnotin $expected) { throw 'Unknown route property.' }
    }
    if ($policy.schema -cne 'h3.routes.v1' -or $policy.mode -cnotin @('laboratory','deployment') -or
        $policy.enabled -isnot [bool] -or -not $policy.enabled) { throw 'Disabled or invalid route policy.' }
    foreach ($field in @('managedRoot','markerName','markerValue')) {
        if ($policy.$field -isnot [string] -or [string]::IsNullOrWhiteSpace($policy.$field)) { throw 'Invalid route property type.' }
    }
    if ($policy.markerName -cnotmatch '^\.[a-z][a-z0-9-]{1,48}$' -or
        $policy.markerValue -cnotmatch '^[A-Z0-9_-]{8,64}$') { throw 'Invalid managed marker.' }
    $repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
    $routePaths = @($policy.managedRoot, $RequestedRoot)
    if ($policy.mode -ceq 'laboratory') {
        if ($null -ne $policy.computerName -or $policy.laboratoryBoundary -isnot [string] -or
            [string]::IsNullOrWhiteSpace($policy.laboratoryBoundary) -or
            [IO.Path]::IsPathRooted($policy.managedRoot) -or [IO.Path]::IsPathRooted($policy.laboratoryBoundary) -or
            $policy.markerName -cne '.synthetic-maintenance-sandbox' -or $policy.markerValue -cne 'H3_SYNTHETIC_ONLY_V1') {
            throw 'Invalid laboratory policy.'
        }
        $routePaths += $policy.laboratoryBoundary
    } else {
        if ($null -ne $policy.laboratoryBoundary -or $policy.computerName -isnot [string] -or
            $policy.computerName -cnotmatch '^[A-Z0-9][A-Z0-9-]{0,62}$' -or
            $policy.computerName -ine $env:COMPUTERNAME -or $policy.managedRoot -notmatch '^[A-Za-z]:[\\/]') {
            throw 'Deployment host or path mismatch.'
        }
    }
    foreach ($path in $routePaths) {
        if ([string]::IsNullOrWhiteSpace($path) -or $path -match '^[\\/]{2}|[*?\[\]]|::' -or
            $path -match '(^|[\\/])\.\.?(?:[\\/]|$)' -or $path -match '[ .]([\\/]|$)' -or
            $path -match '[\x00-\x1f]' -or $path -match ':(?![\\/])') { throw 'Unsafe route syntax.' }
    }
    $root = [IO.Path]::GetFullPath($RequestedRoot).TrimEnd('\','/')
    if ($root -ieq [IO.Path]::GetPathRoot($root).TrimEnd('\','/')) { throw 'Drive root not allowed.' }
    if ($policy.mode -ceq 'laboratory') {
        $authorized = [IO.Path]::GetFullPath((Join-Path $repo $policy.managedRoot)).TrimEnd('\','/')
        $boundary = [IO.Path]::GetFullPath((Join-Path $repo $policy.laboratoryBoundary)).TrimEnd('\','/')
        if (-not $boundary.StartsWith(($repo.TrimEnd('\','/') + '\'), [StringComparison]::OrdinalIgnoreCase) -or
            -not $authorized.StartsWith(($boundary + '\'), [StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid laboratory boundary.' }
    } else { $authorized = [IO.Path]::GetFullPath($policy.managedRoot).TrimEnd('\','/') }
    if ($authorized -ieq [IO.Path]::GetPathRoot($authorized).TrimEnd('\','/') -or $root -ine $authorized) {
        throw 'Requested root is not exactly authorized.'
    }
    $managedDrive = New-Object IO.DriveInfo ([IO.Path]::GetPathRoot($root))
    if ($managedDrive.DriveType -ne [IO.DriveType]::Fixed) { throw 'Managed root must be on a local fixed volume.' }
    Assert-PlainPath $root
    if (-not (Get-Item -LiteralPath $root).PSIsContainer) { throw 'Managed root must be a directory.' }
    [pscustomobject]@{ Root=$root; MarkerName=$policy.markerName; MarkerValue=$policy.markerValue }
}

function Write-MaintenanceRecord {
    param([IO.StreamWriter]$Writer, [hashtable]$Record)
    $Writer.WriteLine(($Record | ConvertTo-Json -Compress -Depth 5))
    $Writer.Flush()
    $Writer.BaseStream.Flush($true)
}

function Invoke-SafeMaintenance {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $true)][Alias('ManagedRoot')][ValidateNotNullOrEmpty()][string]$SandboxRoot,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$ConfigurationPath,
        [ValidateRange(1,3650)][int]$RetentionDays = 14,
        [ValidateRange(1,100)][int]$MaxFiles = 100,
        [ValidateRange(1,10485760)][long]$MaxFileBytes = 10485760
    )
    $ErrorActionPreference = 'Stop'
    $runId = [guid]::NewGuid().ToString('N')
    $result = [ordered]@{
        schema = 'h3.summary.v1'; runId = $runId; timestampUtc = [datetime]::UtcNow.ToString('o')
        mode = 'execute'; succeeded = 0; skipped = 0; failed = 0; planned = 0
        exitCode = 0; reason = 'completed'; audit = $null
    }
    if ($WhatIfPreference) { $result.mode = 'whatif' }
    $lock = $null; $writer = $null; $logStream = $null
    $phase = 'validation'
    try {
        $authorization = Get-AuthorizedRoot -ConfigurationPath $ConfigurationPath -RequestedRoot $SandboxRoot
        $root = $authorization.Root
        $drive = New-Object IO.DriveInfo ([IO.Path]::GetPathRoot($root))
        if ($drive.DriveType -ne [IO.DriveType]::Fixed) { throw 'Only local fixed volumes are allowed.' }
        $marker = Join-Path $root $authorization.MarkerName
        $manifestPath = Join-Path $root 'disposable.json'
        $tempRoot = Join-Path $root 'temp'
        $auditRoot = Join-Path $root 'audit'
        $lockPath = Join-Path $root '.maintenance.lock'
        foreach ($path in @($marker, $manifestPath, $tempRoot, $auditRoot, $lockPath)) { Assert-PlainPath $path }
        if (-not (Get-Item -LiteralPath $tempRoot).PSIsContainer -or -not (Get-Item -LiteralPath $auditRoot).PSIsContainer) {
            throw 'Expected directories.'
        }
        if ((Get-Item -LiteralPath $marker).Length -gt 64 -or
            [IO.File]::ReadAllText($marker).Trim() -cne $authorization.MarkerValue) { throw 'Invalid managed marker.' }
        if ((Get-Item -LiteralPath $manifestPath).Length -gt 65536) { throw 'Manifest too large.' }
        $manifest = [IO.File]::ReadAllText($manifestPath) | ConvertFrom-Json
        if ($manifest.schema -ne 'h3.disposable.v1' -or $manifest.hold -isnot [bool] -or
            $manifest.files -isnot [array] -or $manifest.files.Count -gt $MaxFiles) { throw 'Invalid manifest.' }
        $names = @{}
        foreach ($name in $manifest.files) {
            if ($name -isnot [string] -or $name -cnotmatch '^[A-Za-z0-9][A-Za-z0-9_-]{0,63}\.tmp$' -or $names.ContainsKey($name)) {
                throw 'Invalid or duplicate disposable name.'
            }
            $names[$name] = $true
        }
        $items = @(Get-ChildItem -LiteralPath $tempRoot -Force)
        if ($items.Count -gt $MaxFiles) { throw 'File count limit exceeded.' }
        foreach ($item in $items) { Assert-PlainPath $item.FullName }
        $cutoff = [datetime]::UtcNow.AddDays(-$RetentionDays)
        $plan = New-Object 'System.Collections.Generic.List[object]'
        [long]$totalBytes = 0
        foreach ($item in $items) {
            $reason = 'eligible'
            if ($manifest.hold) { $reason = 'investigation_hold' }
            elseif ($item.PSIsContainer) { $reason = 'directory_preserved' }
            elseif (-not $names.ContainsKey($item.Name)) { $reason = 'not_allowlisted' }
            elseif ($item.LastWriteTimeUtc -ge $cutoff) { $reason = 'recent' }
            elseif ($item.Length -gt $MaxFileBytes) { throw 'File size limit exceeded.' }
            if ($reason -eq 'eligible') { $totalBytes += $item.Length; $result.planned++ }
            $plan.Add([pscustomobject]@{ Item = $item; Name = $item.Name; Reason = $reason })
        }
        if ($totalBytes -gt 52428800) { throw 'Total size limit exceeded.' }
        foreach ($name in $manifest.files) {
            if (-not (Test-Path -LiteralPath (Join-Path $tempRoot $name))) {
                $plan.Add([pscustomobject]@{ Item = $null; Name = $name; Reason = 'already_absent' })
            }
        }
        # This gate covers the complete transaction: lock, audit creation and cleanup.
        # WhatIf exits before ANY filesystem writes or lock acquisition.
        if (-not $PSCmdlet.ShouldProcess('configuration-authorized managed directory', 'Acquire lock, create audit and clean approved expired temporary files')) {
            if ($WhatIfPreference) {
                foreach ($entry in $plan) {
                    if ($entry.Reason -eq 'eligible') {
                        $null = $PSCmdlet.ShouldProcess(('temp/' + $entry.Name), 'Remove allowlisted expired temporary file')
                    }
                }
            }
            $result.skipped = $plan.Count
            $result.reason = 'not_executed'
            return [pscustomobject]$result
        }
        $phase = 'lock'
        $lock = [IO.File]::Open($lockPath, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
        $phase = 'audit'
        Assert-PlainPath $auditRoot
        $logName = $runId + '.jsonl'
        $logStream = [IO.File]::Open((Join-Path $auditRoot $logName), [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::Read)
        $writer = New-Object IO.StreamWriter($logStream, (New-Object Text.UTF8Encoding($false)))
        $result.audit = 'audit/' + $logName
        Write-MaintenanceRecord $writer @{ schema='h3.event.v1'; runId=$runId; timestampUtc=[datetime]::UtcNow.ToString('o'); action='run'; status='started'; retentionDays=$RetentionDays }
        foreach ($entry in $plan) {
            $phase = 'audit'
            if ($entry.Reason -ne 'eligible') {
                $result.skipped++
                Write-MaintenanceRecord $writer @{ schema='h3.event.v1'; runId=$runId; timestampUtc=[datetime]::UtcNow.ToString('o'); action='preserve'; status='skipped'; reason=$entry.Reason; file=('temp/' + $entry.Name) }
                continue
            }
            $item = $entry.Item
            if (-not $PSCmdlet.ShouldProcess(('temp/' + $item.Name), 'Remove allowlisted expired temporary file')) {
                $result.skipped++
                Write-MaintenanceRecord $writer @{ schema='h3.event.v1'; runId=$runId; timestampUtc=[datetime]::UtcNow.ToString('o'); action='remove'; status='skipped'; reason='declined'; file=('temp/' + $item.Name) }
                continue
            }
            # Recheck policy and metadata immediately before action. No following links.
            $phase = 'operation'
            $failureReason = $null
            try {
                $rechecked = Get-AuthorizedRoot -ConfigurationPath $ConfigurationPath -RequestedRoot $root
                Assert-PlainPath $marker
                if ($rechecked.MarkerName -cne $authorization.MarkerName -or
                    [IO.File]::ReadAllText($marker).Trim() -cne $rechecked.MarkerValue) { throw 'Marker changed.' }
                Assert-PlainPath $item.FullName
                Assert-PlainPath $manifestPath
                $currentPolicy = [IO.File]::ReadAllText($manifestPath) | ConvertFrom-Json
                if ($currentPolicy.hold -ne $false -or $item.Name -cnotin $currentPolicy.files) { throw 'Policy changed.' }
                $current = Get-Item -LiteralPath $item.FullName -Force
                if ($current.PSIsContainer -or $current.LastWriteTimeUtc -ge $cutoff -or
                    $current.Length -ne $item.Length -or $current.LastWriteTimeUtc -ne $item.LastWriteTimeUtc) { throw 'File changed.' }
                $hash = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash
            } catch { $failureReason = 'precondition_failed' }
            if ($null -eq $failureReason) {
                $phase = 'audit'
                Write-MaintenanceRecord $writer @{ schema='h3.event.v1'; runId=$runId; timestampUtc=[datetime]::UtcNow.ToString('o'); action='remove'; status='intent'; file=('temp/' + $item.Name); sha256=$hash; bytes=$current.Length }
                $phase = 'operation'
                try {
                    Remove-MaintenanceFile -LiteralPath $item.FullName
                    if (Test-Path -LiteralPath $item.FullName) { throw 'Removal not verified.' }
                } catch { $failureReason = 'remove_or_verification_failed' }
            }
            $phase = 'audit'
            if ($null -ne $failureReason) {
                $result.failed++
                Write-MaintenanceRecord $writer @{ schema='h3.event.v1'; runId=$runId; timestampUtc=[datetime]::UtcNow.ToString('o'); action='remove'; status='failed'; reason=$failureReason; file=('temp/' + $item.Name) }
            } else {
                $result.succeeded++
                Write-MaintenanceRecord $writer @{ schema='h3.event.v1'; runId=$runId; timestampUtc=[datetime]::UtcNow.ToString('o'); action='remove'; status='succeeded'; file=('temp/' + $item.Name) }
            }
        }
        if ($result.failed -gt 0) { $result.exitCode = 3; $result.reason = 'operation_failures' }
        Write-MaintenanceRecord $writer @{ schema='h3.event.v1'; runId=$runId; timestampUtc=[datetime]::UtcNow.ToString('o'); action='summary'; status='completed'; summary=[pscustomobject]$result }
    } catch {
        if ($phase -eq 'validation') { $result.exitCode = 2; $result.reason = 'validation_failed' }
        elseif ($phase -eq 'lock' -and ($_.Exception.InnerException -is [IO.IOException] -or $_.Exception -is [IO.IOException])) {
            $result.exitCode = 4; $result.reason = 'lock_unavailable'
        } else { $result.exitCode = 5; $result.reason = 'audit_or_infrastructure_failed' }
        $result.failed++
    } finally {
        try { if ($null -ne $writer) { $writer.Dispose() } elseif ($null -ne $logStream) { $logStream.Dispose() } }
        catch { $result.exitCode = 5; $result.reason = 'audit_close_failed' }
        if ($null -ne $lock) { $lock.Dispose() }
    }
    [pscustomobject]$result
}

Export-ModuleMember -Function Invoke-SafeMaintenance
