#requires -Version 5.1
# LOCAL ONLY. Packages public example files; never reads private inputs or real policy.
[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
$source=Split-Path $PSScriptRoot -Parent
$repo=Split-Path $source -Parent
$out=Join-Path $repo ('work-private/h4-packages/' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($out)|Out-Null
Compress-Archive -Path (Join-Path $source 'modules/H4SafeAutomation') -DestinationPath (Join-Path $out 'H4SafeAutomation.zip')
Compress-Archive -Path (Join-Path $source 'modules'),(Join-Path $source 'scripts'),(Join-Path $source 'config') -DestinationPath (Join-Path $out 'H4Guest.zip')
Get-ChildItem $out -Filter '*.zip' | ForEach-Object { [pscustomobject]@{file=$_.Name;sha256=(Get-FileHash $_.FullName).Hash;directory=$out.Substring($repo.Length+1)} }
