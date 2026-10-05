#requires -Version 5.1
# Future, separately authorized failure injection on the lab VM only.
[CmdletBinding(SupportsShouldProcess,ConfirmImpact='High')]
param([Parameter(Mandatory)][switch]$ApprovedLabFault)
$ErrorActionPreference='Stop'
if (!$ApprovedLabFault -or $env:COMPUTERNAME -ine 'vm-h4-iis') { throw 'AuthorizedLabHostRequired' }
Import-Module WebAdministration
$site=Get-Website -Name H4LabSite
if ($site.applicationPool -cne 'H4LabPool' -or (Get-WebAppPoolState H4LabPool).Value -ne 'Started') { throw 'ExpectedHealthyLabPoolRequired' }
if ($PSCmdlet.ShouldProcess('H4LabPool on vm-h4-iis','Induce lab failure by stopping only this pool')) {
    $start=[datetime]::UtcNow.ToString('o')
    Stop-WebAppPool -Name H4LabPool -ErrorAction Stop
    $deadline=[datetime]::UtcNow.AddSeconds(15)
    do {
        $state=(Get-WebAppPoolState H4LabPool).Value
        if ($state -eq 'Stopped') { break }
        Start-Sleep -Milliseconds 250
    } while ([datetime]::UtcNow -lt $deadline)
    if ($state -ne 'Stopped') { throw 'StopNotVerified' }
    @{schema='h4.fault.v1';faultStartedUtc=$start;verifiedUtc=[datetime]::UtcNow.ToString('o');pool='H4LabPool';status='Stopped'} | ConvertTo-Json -Compress
}
