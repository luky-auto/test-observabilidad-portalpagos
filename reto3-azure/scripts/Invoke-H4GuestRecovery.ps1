#requires -Version 5.1
[CmdletBinding(SupportsShouldProcess)]
param([Parameter(Mandatory)][ValidatePattern('^[a-f0-9]{64}$')][string]$Incident)
$ErrorActionPreference = 'Stop'
$root = 'C:\ProgramData\H4Lab'
Import-Module "$root\H4SafeAutomation\H4SafeAutomation.psd1" -Force
$policy = Get-Content "$root\policy.json" -Raw -Encoding UTF8 | ConvertFrom-Json
Import-Module WebAdministration -ErrorAction Stop
$get = {
    $site = Get-Website -Name 'H4LabSite' -ErrorAction Stop
    $bindings = @($site.bindings.Collection)
    [pscustomobject]@{site=$site.Name;pool=$site.applicationPool;state=(Get-WebAppPoolState -Name 'H4LabPool').Value;
        bindingValid=($bindings.Count -eq 1 -and $bindings[0].protocol -eq 'http' -and $bindings[0].bindingInformation -ceq '127.0.0.1:8080:')}
}
$start = { Start-WebAppPool -Name 'H4LabPool' -ErrorAction Stop }
$probe = {
    # Bounded warm-up: six attempts, each <=5s, with 2s between failures.
    $code = 0; $body = ''
    for ($i=0; $i -lt 6; $i++) {
        try {
            $h = Invoke-WebRequest -Uri 'http://127.0.0.1:8080/health.txt' -UseBasicParsing -TimeoutSec 5 -MaximumRedirection 0 -ErrorAction Stop
            $code = [int]$h.StatusCode; $body = [string]$h.Content
        } catch {
            $code = 0; $body = ''
            if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }
        }
        if (Test-H4Http $code $body) { break }
        if ($i -lt 5) { Start-Sleep -Seconds 2 }
    }
    [pscustomobject]@{statusCode=$code;body=$body}
}
try {
    $r = Invoke-H4Recovery -Policy $policy -Incident $Incident -StateDirectory "$root\state" -GetState $get -StartPool $start -Probe $probe -WhatIf:$WhatIfPreference
    $r | ConvertTo-Json -Compress
} catch {
    # No raw exception: paths, request metadata or response bodies never leave the VM.
    @{schema='h4.result.v1';status='EscalationRequired';incident=$Incident;timestampUtc=[datetime]::UtcNow.ToString('o');reason='GuestValidationOrStateFailure'} | ConvertTo-Json -Compress
}
