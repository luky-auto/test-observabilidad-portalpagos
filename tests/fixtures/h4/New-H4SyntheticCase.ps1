# Synthetic only. No network, IIS, services, registry or scheduled tasks.
$repo = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
$policy = Get-Content (Join-Path $PSScriptRoot 'policy.synthetic.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$base = '/subscriptions/' + $policy.subscriptionId
$ids = Assert-H4Policy $policy
$alert = [pscustomobject]@{
    schemaId='azureMonitorCommonAlertSchema'
    data=[pscustomobject]@{
        essentials=[pscustomobject]@{essentialsVersion='1.0';signalType='Log';alertRule=$policy.alertRule;alertRuleId=$ids.ruleId;
            alertId="$base/providers/Microsoft.AlertsManagement/alerts/22222222-2222-4222-8222-222222222222";
            alertTargetIDs=@($ids.workspaceId);monitorCondition='Fired';firedDateTime=[datetime]::UtcNow.ToString('o')}
        alertContext=[pscustomobject]@{condition=[pscustomobject]@{allOf=@([pscustomobject]@{dimensions=@(
            [pscustomobject]@{name='_ResourceId';value=$ids.vmId},
            [pscustomobject]@{name='Site';value=$policy.site},
            [pscustomobject]@{name='Pool';value=$policy.pool}
        )})}}
    }
}
$sandbox = Join-Path $repo ('work-private/h4-sandboxes/' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($sandbox) | Out-Null
[IO.File]::WriteAllText((Join-Path $sandbox 'ledger.json'),'{"schema":"h4.ledger.v1","records":[]}')
[IO.File]::WriteAllText((Join-Path $sandbox 'recovery.lock'),'')
[pscustomobject]@{policy=$policy;alert=$alert;sandbox=$sandbox;incident=('a'*64)}
