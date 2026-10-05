#requires -Version 5.1
# Import H4SafeAutomation custom module first; publish only after review and future Azure tests.
[CmdletBinding()]
param([object]$WebhookData)
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'SilentlyContinue'
$DebugPreference = 'SilentlyContinue'
Import-Module H4SafeAutomation -ErrorAction Stop
$incident = ''
try {
    $policy = Get-AutomationVariable -Name H4Policy | ConvertFrom-Json
    $ids = Assert-H4Policy $policy
    $alert = Read-H4Alert -WebhookData $WebhookData -Policy $policy
    $incident = $alert.incident
    if ($alert.status -ne 'Fired') {
        @{schema='h4.result.v1';status=$alert.status;timestampUtc=[datetime]::UtcNow.ToString('o')} | ConvertTo-Json -Compress
        return
    }
    Disable-AzContextAutosave -Scope Process | Out-Null
    $context = (Connect-AzAccount -Identity -Subscription $policy.subscriptionId -ErrorAction Stop).Context
    if ($context.Subscription.Id -ine $policy.subscriptionId) { throw 'SubscriptionContext' }
    # Fixed command text; the sole webhook-derived argument is a validated SHA256 hex identifier.
    $script = "& 'C:\ProgramData\H4Lab\Invoke-H4GuestRecovery.ps1' -Incident '$incident'"
    $response = Invoke-AzVMRunCommand -ResourceGroupName $policy.resourceGroup -VMName $policy.vmName -CommandId RunPowerShellScript -ScriptString $script -DefaultProfile $context -ErrorAction Stop
    $out = @($response.Value | Where-Object {$_.Code -eq 'ComponentStatus/StdOut/succeeded'})
    $err = @($response.Value | Where-Object {$_.Code -like '*StdErr*' -and ![string]::IsNullOrWhiteSpace($_.Message)})
    if ($out.Count -ne 1 -or $err.Count -gt 0) { throw 'RunCommandOutput' }
    $r = $out[0].Message.Trim() | ConvertFrom-Json
    if ($r.schema -cne 'h4.result.v1' -or $r.incident -cne $incident -or $r.status -cnotin @('Recovered','AlreadyHealthy','Duplicate','Busy','Disabled','AttemptsExhausted','EscalationRequired')) { throw 'GuestResult' }
    # Emit only a fixed allowlist; never raw Run Command output.
    $attempts = 0; $httpStatus = 0
    if ($r.PSObject.Properties['attempts']) { $attempts = [int]$r.attempts }
    if ($r.PSObject.Properties['httpStatus']) { $httpStatus = [int]$r.httpStatus }
    if ($attempts -lt 0 -or $attempts -gt 2 -or $httpStatus -lt 0 -or $httpStatus -gt 599) { throw 'GuestResultRange' }
    if ($r.status -in @('Recovered','AlreadyHealthy') -and $httpStatus -ne 200) { throw 'GuestHttpNotVerified' }
    @{schema='h4.result.v1';incident=$incident;status=$r.status;attempts=$attempts;httpStatus=$httpStatus;timestampUtc=[datetime]::UtcNow.ToString('o')} | ConvertTo-Json -Compress
    if ($r.status -in @('AttemptsExhausted','EscalationRequired','Busy')) { throw 'HumanReviewRequired' }
} catch {
    @{schema='h4.result.v1';incident=$incident;status='EscalationRequired';timestampUtc=[datetime]::UtcNow.ToString('o')} | ConvertTo-Json -Compress
    # No automatic resubmission: indeterminate transport may hide a still-running command.
    throw 'H4 remediation stopped; inspect sanitized job status and guest ledger.'
}
