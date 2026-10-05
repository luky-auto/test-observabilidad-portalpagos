#requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function ConvertFrom-H4Json {
    param([string]$Text)
    # 7.5+ otherwise converts ISO timestamps to DateTime; 5.1 preserves strings.
    $options = @{}
    if ((Get-Command ConvertFrom-Json).Parameters.ContainsKey('DateKind')) { $options.DateKind='String' }
    $Text | ConvertFrom-Json @options
}

function Assert-H4Policy {
    param([Parameter(Mandatory)]$Policy)
    $keys = @('schema','enabled','maintenance','subscriptionId','resourceGroup','vmName','workspaceName','alertRule','site','pool','uri','expectedBody','maxAttempts','windowMinutes')
    $actual = @($Policy.PSObject.Properties.Name)
    if (@(Compare-Object $keys $actual).Count) { throw 'PolicySchema' }
    if ($Policy.schema -cne 'h4.policy.v1' -or $Policy.enabled -isnot [bool] -or $Policy.maintenance -isnot [bool]) { throw 'PolicySchema' }
    if ($Policy.subscriptionId -isnot [string] -or $Policy.subscriptionId -cnotmatch '^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$') { throw 'SubscriptionRequired' }
    $fixed = @{resourceGroup='rg-h4-observabilidad'; vmName='vm-h4-iis'; workspaceName='law-h4-test'; alertRule='alert-h4-http-failed'; site='H4LabSite'; pool='H4LabPool'; uri='http://127.0.0.1:8080/health.txt'; expectedBody='H4_OK'}
    foreach ($k in $fixed.Keys) { if ($Policy.$k -isnot [string] -or $Policy.$k -cne $fixed[$k]) { throw 'PolicyTarget' } }
    if ($Policy.maxAttempts -isnot [int] -and $Policy.maxAttempts -isnot [long]) { throw 'PolicyLimit' }
    if ($Policy.windowMinutes -isnot [int] -and $Policy.windowMinutes -isnot [long]) { throw 'PolicyLimit' }
    if ($Policy.maxAttempts -ne 2 -or $Policy.windowMinutes -ne 15) { throw 'PolicyLimit' }
    $base = '/subscriptions/{0}/resourceGroups/{1}/providers' -f $Policy.subscriptionId,$Policy.resourceGroup
    [pscustomobject]@{
        vmId="$base/Microsoft.Compute/virtualMachines/$($Policy.vmName)"
        workspaceId="$base/Microsoft.OperationalInsights/workspaces/$($Policy.workspaceName)"
        ruleId="$base/Microsoft.Insights/scheduledQueryRules/$($Policy.alertRule)"
    }
}

function Read-H4Alert {
    param([Parameter(Mandatory)]$WebhookData,[Parameter(Mandatory)]$Policy,[datetimeoffset]$Now=[datetimeoffset]::UtcNow)
    $ids = Assert-H4Policy $Policy
    if (!$Policy.enabled -or $Policy.maintenance) { return [pscustomobject]@{status='Disabled'; incident=''} }
    try {
        if ($WebhookData -is [string]) { $WebhookData = ConvertFrom-H4Json $WebhookData }
        $body = $WebhookData.RequestBody
        if ($body -isnot [string] -or $body.Length -gt 65536) { throw 'Body' }
        $a = ConvertFrom-H4Json $body
        $e = $a.data.essentials
        if ($a.schemaId -cne 'azureMonitorCommonAlertSchema' -or $e.essentialsVersion -cne '1.0' -or $e.signalType -cne 'Log') { throw 'Schema' }
        if ($e.alertRule -cne $Policy.alertRule) { throw 'Rule' }
        if ($e.PSObject.Properties['alertRuleId'] -and $e.alertRuleId -ine $ids.ruleId) { throw 'RuleId' }
        if (@($e.alertTargetIDs).Count -ne 1 -or $e.alertTargetIDs[0] -ine $ids.workspaceId) { throw 'Target' }
        $pattern = '^/subscriptions/' + [regex]::Escape($Policy.subscriptionId) + '/providers/Microsoft.AlertsManagement/alerts/[0-9a-fA-F-]{36}$'
        if ($e.alertId -notmatch $pattern) { throw 'AlertId' }
        $conditions = @($a.data.alertContext.condition.allOf)
        if ($conditions.Count -ne 1) { throw 'Conditions' }
        $dims = @($conditions[0].dimensions)
        $expected = @{_ResourceId=$ids.vmId; Site=$Policy.site; Pool=$Policy.pool}
        if ($dims.Count -ne 3) { throw 'Dimensions' }
        foreach ($name in $expected.Keys) {
            $d = @($dims | Where-Object { $_.name -ceq $name })
            if ($d.Count -ne 1 -or $d[0].value -ine $expected[$name]) { throw 'DimensionTarget' }
        }
        if ($e.monitorCondition -ceq 'Resolved') { return [pscustomobject]@{status='Resolved';incident=''} }
        # Common Alert Schema uses Fired. Legacy Activated is deliberately not accepted.
        if ($e.monitorCondition -cne 'Fired') { throw 'State' }
        if ($e.firedDateTime -notmatch 'Z$') { throw 'TimeZone' }
        $fired = [datetimeoffset]::Parse($e.firedDateTime,[cultureinfo]::InvariantCulture)
        if (($Now-$fired).TotalMinutes -gt 15 -or ($Now-$fired).TotalSeconds -lt -60) { throw 'Stale' }
        $sha = [Security.Cryptography.SHA256]::Create()
        try { $id = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($e.alertId.ToLowerInvariant())))).Replace('-','').ToLowerInvariant() } finally { $sha.Dispose() }
        return [pscustomobject]@{status='Fired';incident=$id}
    } catch { throw 'RejectedAlert' } # Do not log request, headers, URL or parser exceptions.
}

function Test-H4Http {
    param([int]$StatusCode,[AllowNull()][string]$Body)
    return ($StatusCode -eq 200 -and $null -ne $Body -and $Body.Trim() -ceq 'H4_OK')
}

function Test-H4TwoFailures {
    # Synthetic reference for the KQL contract, not a KQL execution engine.
    param([object[]]$Probes,[datetimeoffset]$Now=[datetimeoffset]::UtcNow)
    $p = @($Probes | Sort-Object timestampUtc -Descending | Group-Object probeId | ForEach-Object { $_.Group[0] } | Sort-Object timestampUtc -Descending | Select-Object -First 2)
    if ($p.Count -ne 2) { return $false }
    $new = [datetimeoffset]::Parse($p[0].timestampUtc)
    $old = [datetimeoffset]::Parse($p[1].timestampUtc)
    return (!$p[0].success -and !$p[1].success -and ($new-$old).TotalSeconds -ge 45 -and ($new-$old).TotalSeconds -le 90 -and ($Now-$new).TotalSeconds -ge 0 -and ($Now-$new).TotalSeconds -le 150)
}

function Invoke-H4Recovery {
    # Adapters supplied only by trusted local entrypoint or synthetic tests, never webhook fields.
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)]$Policy,[Parameter(Mandatory)][ValidatePattern('^[a-f0-9]{64}$')][string]$Incident,
        [Parameter(Mandatory)][string]$StateDirectory,[Parameter(Mandatory)][scriptblock]$GetState,
        [Parameter(Mandatory)][scriptblock]$StartPool,[Parameter(Mandatory)][scriptblock]$Probe,
        [datetimeoffset]$Now=[datetimeoffset]::UtcNow)
    $null = Assert-H4Policy $Policy
    $result = [ordered]@{schema='h4.result.v1';startedUtc=$Now.ToString('o');timestampUtc=$Now.ToString('o');incident=$Incident;status='Disabled';attempts=0;httpStatus=0}
    if (!$Policy.enabled -or $Policy.maintenance) { return [pscustomobject]$result }
    if (!$PSCmdlet.ShouldProcess($Policy.pool,'Validate, lock, persist attempts, start stopped lab pool and verify HTTP')) { $result.status='WhatIf'; return [pscustomobject]$result }
    # No directory creation or state reset here. Missing/corrupt state must fail closed.
    $dir = Get-Item -LiteralPath $StateDirectory -Force -ErrorAction Stop
    if (!$dir.PSIsContainer) { throw 'StateDirectory' }
    for ($part=$dir; $null -ne $part; $part=$part.Parent) { if ($part.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'StateReparse' } }
    $ledger = Join-Path $dir.FullName 'ledger.json'
    $lockPath = Join-Path $dir.FullName 'recovery.lock'
    foreach ($p in @($ledger,$lockPath)) { if ((Get-Item -LiteralPath $p -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'StateReparse' } }
    try { $lock = [IO.File]::Open($lockPath,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None) }
    catch { $result.status='Busy'; return [pscustomobject]$result }
    try {
        $s = ConvertFrom-H4Json (Get-Content -LiteralPath $ledger -Raw -Encoding UTF8)
        if ($s.schema -cne 'h4.ledger.v1' -or $s.records -isnot [array]) { throw 'InvalidLedger' }
        foreach ($r in $s.records) {
            if ($r.incident -cnotmatch '^[a-f0-9]{64}$' -or $r.attempts -lt 0 -or $r.attempts -gt 2 -or $r.status -cnotin @('Pending','Recovered','AttemptsExhausted','EscalationRequired','AlreadyHealthy')) { throw 'InvalidLedger' }
            $null = [datetimeoffset]::Parse($r.timestampUtc)
        }
        $prior = @($s.records | Where-Object {$_.incident -ceq $Incident})
        if ($prior.Count) {
            if ($prior[0].status -ceq 'Pending') { $result.status='EscalationRequired' } else { $result.status='Duplicate' }
            return [pscustomobject]$result
        }
        if (@($s.records | Where-Object {$_.status -ceq 'Pending'}).Count) { $result.status='EscalationRequired'; return [pscustomobject]$result }
        $recent = @($s.records | Where-Object { ([datetimeoffset]::Parse($_.timestampUtc)) -ge $Now.AddMinutes(-15) })
        $used = 0
        foreach ($entry in $recent) { $used += [int]$entry.attempts }
        if ($used -ge 2) { $result.status='AttemptsExhausted'; return [pscustomobject]$result }
        if ($s.records.Count -ge 500) { throw 'LedgerCapacity' } # No automatic pruning of evidence.
        $record = [pscustomobject]@{incident=$Incident;timestampUtc=$Now.ToString('o');attempts=0;status='Pending'}
        $s.records = @($s.records) + @($record)
        $save = {
            $temp = Join-Path $dir.FullName ([guid]::NewGuid().ToString('N') + '.tmp')
            $bytes = [Text.Encoding]::UTF8.GetBytes(($s | ConvertTo-Json -Depth 6 -Compress))
            $f = [IO.File]::Open($temp,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
            try { $f.Write($bytes,0,$bytes.Length); $f.Flush($true) } finally { $f.Dispose() }
            [IO.File]::Replace($temp,$ledger,[NullString]::Value)
        }
        & $save # Durable claim before any external effect.
        while ($record.attempts -lt 2 -and ($used + $record.attempts) -lt 2) {
            $state = & $GetState
            if ($state.site -cne $Policy.site -or $state.pool -cne $Policy.pool -or !$state.bindingValid) { $result.status='EscalationRequired'; break }
            if ($state.state -ceq 'Started') {
                $http = & $Probe
                $result.httpStatus = $http.statusCode
                if (Test-H4Http $http.statusCode $http.body) { $result.status='AlreadyHealthy' } else { $result.status='EscalationRequired' }
                break
            }
            if ($state.state -cne 'Stopped') { $result.status='EscalationRequired'; break }
            $record.attempts++
            $record.timestampUtc = [datetimeoffset]::UtcNow.ToString('o')
            & $save # Count even a crash, timeout or partial failure as an attempt.
            try { & $StartPool | Out-Null } catch { } # Verify actual state and HTTP, never assume success.
            $after = & $GetState
            $http = & $Probe
            $result.httpStatus = $http.statusCode
            if ($after.site -ceq $Policy.site -and $after.pool -ceq $Policy.pool -and $after.bindingValid -and $after.state -ceq 'Started' -and (Test-H4Http $http.statusCode $http.body)) { $result.status='Recovered'; break }
            $result.status='AttemptsExhausted'
        }
        $result.attempts = $record.attempts
        $result.timestampUtc = [datetimeoffset]::UtcNow.ToString('o')
        $record.status = $result.status
        & $save
        return [pscustomobject]$result
    } finally { $lock.Dispose() }
}
Export-ModuleMember -Function Assert-H4Policy,Read-H4Alert,Test-H4Http,Invoke-H4Recovery,Test-H4TwoFailures
