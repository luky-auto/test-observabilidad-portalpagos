#requires -Version 5.1
# Installed only on the authorized VM. Never executed by local tests.
$ErrorActionPreference = 'Stop'
Import-Module 'C:\ProgramData\H4Lab\H4SafeAutomation\H4SafeAutomation.psd1' -Force
$timer = [Diagnostics.Stopwatch]::StartNew()
$code = 0; $ok = $false; $category = 'None'
try {
    $r = Invoke-WebRequest -Uri 'http://127.0.0.1:8080/health.txt' -TimeoutSec 5 -MaximumRedirection 0 -UseBasicParsing -ErrorAction Stop
    $code = [int]$r.StatusCode
    $ok = Test-H4Http $code ([string]$r.Content)
    if (!$ok) { $category = 'UnexpectedResponse' }
} catch {
    $category = 'TransportOrHttpError'
    if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }
}
$timer.Stop()
$record = [ordered]@{
    schema='h4.probe.v1';probeId=[guid]::NewGuid().ToString();timestampUtc=[datetime]::UtcNow.ToString('o')
    site='H4LabSite';pool='H4LabPool';httpStatus=$code;success=$ok;durationMs=$timer.ElapsedMilliseconds;errorCategory=$category
}
Write-EventLog -LogName Application -Source H4AvailabilityProbe -EntryType Information -EventId 100 -Message ($record | ConvertTo-Json -Compress)
