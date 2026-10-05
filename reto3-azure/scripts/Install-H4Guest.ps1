#requires -Version 5.1
# FUTURE VM ONLY: installing IIS and a scheduled task changes the guest.
[CmdletBinding(SupportsShouldProcess,ConfirmImpact='High')]
param([Parameter(Mandatory)][string]$PackageDirectory,[Parameter(Mandatory)][string]$PolicyPath,
    [Parameter(Mandatory)][switch]$ApprovedLabDeployment)
$ErrorActionPreference = 'Stop'
if (!$ApprovedLabDeployment -or $env:COMPUTERNAME -ine 'vm-h4-iis') { throw 'AuthorizedLabHostRequired' }
Import-Module (Join-Path $PackageDirectory 'modules/H4SafeAutomation/H4SafeAutomation.psd1') -Force
$policy = Get-Content -LiteralPath $PolicyPath -Raw -Encoding UTF8 | ConvertFrom-Json
$null = Assert-H4Policy $policy
if ($policy.enabled) { throw 'InstallWithDisabledPolicy' }
$root = 'C:\ProgramData\H4Lab'
if (Test-Path -LiteralPath $root) { throw 'ExistingInstallationRequiresReview_NoReset' }
if (!$PSCmdlet.ShouldProcess('vm-h4-iis','Install IIS, isolated site, protected H4 files and disabled probe task')) { return }
$feature = Install-WindowsFeature Web-Server,Web-Scripting-Tools -ErrorAction Stop
if (!$feature.Success -or $feature.RestartNeeded -eq 'Yes') { throw 'FeatureInstallNeedsReview_NoAutomaticRestart' }
Import-Module WebAdministration
if ((Test-Path IIS:\Sites\H4LabSite) -or (Test-Path IIS:\AppPools\H4LabPool)) { throw 'ExistingSiteOrPool' }
New-Item -ItemType Directory -Path $root,"$root\state","$root\www" | Out-Null
# Restrict code, policy and recovery state to SYSTEM and local Administrators (well-known SIDs).
& icacls.exe $root /inheritance:r /grant:r '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'AclFailure' }
Copy-Item (Join-Path $PackageDirectory 'modules/H4SafeAutomation') $root -Recurse
Copy-Item (Join-Path $PackageDirectory 'scripts/Invoke-H4Probe.ps1') $root
Copy-Item (Join-Path $PackageDirectory 'scripts/Invoke-H4GuestRecovery.ps1') $root
Copy-Item -LiteralPath $PolicyPath -Destination "$root\policy.json"
[IO.File]::WriteAllText("$root\www\health.txt",'H4_OK')
[IO.File]::WriteAllText("$root\state\ledger.json",'{"schema":"h4.ledger.v1","records":[]}')
[IO.File]::WriteAllText("$root\state\recovery.lock",'')
New-WebAppPool -Name H4LabPool | Out-Null
Set-ItemProperty IIS:\AppPools\H4LabPool -Name managedRuntimeVersion -Value ''
New-Website -Name H4LabSite -Port 8080 -IPAddress 127.0.0.1 -PhysicalPath "$root\www" -ApplicationPool H4LabPool | Out-Null
Set-WebConfigurationProperty -PSPath IIS:\ -Location H4LabSite -Filter system.webServer/security/authentication/anonymousAuthentication -Name userName -Value ''
& icacls.exe "$root\www" /grant 'IIS AppPool\H4LabPool:(OI)(CI)RX' | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'SiteAclFailure' }
# Probe uses LOCAL SERVICE, no password and no control over app pools.
foreach ($p in @("$root\Invoke-H4Probe.ps1","$root\H4SafeAutomation")) {
    & icacls.exe $p /grant '*S-1-5-19:RX' /T | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'ProbeAclFailure' }
}
if (![Diagnostics.EventLog]::SourceExists('H4AvailabilityProbe')) { New-EventLog -LogName Application -Source H4AvailabilityProbe }
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -NonInteractive -File C:\ProgramData\H4Lab\Invoke-H4Probe.ps1'
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 1)
$principal = New-ScheduledTaskPrincipal -UserId 'S-1-5-19' -LogonType ServiceAccount -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Seconds 30) -StartWhenAvailable -Disable
Register-ScheduledTask -TaskName H4-AvailabilityProbe -Action $action -Trigger $trigger -Principal $principal -Settings $settings | Out-Null
# No automatic activation, IIS reset, service restart, deletion or fault injection.
