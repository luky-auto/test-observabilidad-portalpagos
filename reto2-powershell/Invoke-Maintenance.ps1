#requires -Version 5.1
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true)][Alias('ManagedRoot')][ValidateNotNullOrEmpty()][string]$SandboxRoot,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$ConfigurationPath,
    [ValidateRange(1,3650)][int]$RetentionDays = 14,
    [ValidateRange(1,100)][int]$MaxFiles = 100,
    [ValidateRange(1,10485760)][long]$MaxFileBytes = 10485760
)
$ErrorActionPreference = 'Stop'
try {
    Import-Module (Join-Path $PSScriptRoot 'SafeMaintenance.psm1') -Force
    $arguments = @{
        SandboxRoot=$SandboxRoot; ConfigurationPath=$ConfigurationPath; RetentionDays=$RetentionDays; MaxFiles=$MaxFiles
        MaxFileBytes=$MaxFileBytes; WhatIf=[bool]$WhatIfPreference
    }
    if ($PSBoundParameters.ContainsKey('Confirm')) { $arguments.Confirm = $PSBoundParameters.Confirm }
    $result = Invoke-SafeMaintenance @arguments
    $result | ConvertTo-Json -Compress -Depth 5
    exit $result.exitCode
} catch {
    # Never serialize raw exceptions, which may contain personal paths.
    Write-Output '{"schema":"h3.summary.v1","exitCode":5,"reason":"entrypoint_failed"}'
    exit 5
}
