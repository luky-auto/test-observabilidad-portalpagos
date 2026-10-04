#requires -Version 5.1
BeforeAll {
    $repo = Split-Path $PSScriptRoot -Parent
    Import-Module (Join-Path $repo 'reto2-powershell/SafeMaintenance.psm1') -Force
    $fixture = Join-Path $PSScriptRoot 'fixtures/h3/New-SyntheticSandbox.ps1'
    $cli = Join-Path $repo 'reto2-powershell/Invoke-Maintenance.ps1'
    $engine = (Get-Process -Id $PID).Path
    function Get-Snapshot([string]$Root) {
        @(Get-ChildItem -LiteralPath $Root -Recurse -Force | Sort-Object FullName | ForEach-Object {
            $hash = ''; if (-not $_.PSIsContainer) { $hash = (Get-FileHash -LiteralPath $_.FullName).Hash }
            '{0}|{1}|{2}' -f $_.FullName.Substring($Root.Length), $_.LastWriteTimeUtc.Ticks, $hash
        }) -join "`n"
    }
    function Set-Policy([string]$Root, [bool]$Hold, [string[]]$Names) {
        @{schema='h3.disposable.v1'; hold=$Hold; files=@($Names)} | ConvertTo-Json |
            Set-Content -LiteralPath (Join-Path $Root 'disposable.json') -Encoding UTF8
    }
}

Describe 'H3 synthetic maintenance safety contract' {
    BeforeEach { $sandbox = & $fixture; $configPath = Join-Path $sandbox 'maintenance.routes.json' }

    It 'WhatIf preserves the complete snapshot and creates no audit file' {
        $before = Get-Snapshot $sandbox
        $r = Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $sandbox -WhatIf
        $r.exitCode | Should -Be 0
        $r.mode | Should -Be 'whatif'
        $r.planned | Should -Be 1
        $r.succeeded | Should -Be 0
        $r.audit | Should -BeNullOrEmpty
        (Get-Snapshot $sandbox) | Should -BeExactly $before
    }
    It 'removes only allowlisted expired files and preserves evidence byte for byte' {
        $protected = @('temp/recent.tmp','temp/unlisted.tmp','temp/evidence.dmp','logs/synthetic.log','dumps/synthetic.dmp')
        $hashes = @{}; foreach ($p in $protected) { $hashes[$p] = (Get-FileHash -LiteralPath (Join-Path $sandbox $p)).Hash }
        $r = Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $sandbox -Confirm:$false
        $r.exitCode | Should -Be 0
        $r.succeeded | Should -Be 1
        $r.skipped | Should -Be 3
        Test-Path -LiteralPath (Join-Path $sandbox 'temp/expired.tmp') | Should -BeFalse
        foreach ($p in $protected) { (Get-FileHash -LiteralPath (Join-Path $sandbox $p)).Hash | Should -Be $hashes[$p] }
    }
    It 'repeats safely with no second deletion' {
        $first = Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $sandbox -Confirm:$false
        $second = Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $sandbox -Confirm:$false
        $first.succeeded | Should -Be 1
        $second.exitCode | Should -Be 0
        $second.succeeded | Should -Be 0
        $second.skipped | Should -Be 4
        $records = @(Get-Content -LiteralPath (Join-Path $sandbox $second.audit) | ForEach-Object { $_ | ConvertFrom-Json })
        ($records | Where-Object { $_.reason -eq 'already_absent' }).file | Should -Be 'temp/expired.tmp'
    }
    It 'rejects a nonexistent root without creating it' {
        $missing = Join-Path $sandbox 'missing'
        (Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $missing).exitCode | Should -Be 2
        Test-Path -LiteralPath $missing | Should -BeFalse
    }
    It 'rejects a root outside the sandbox boundary without changes' {
        $before = Get-Snapshot $sandbox
        (Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $repo).exitCode | Should -Be 2
        (Get-Snapshot $sandbox) | Should -BeExactly $before
    }
    It 'rejects empty paths at parameter binding' {
        { Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot '' } | Should -Throw
    }
    It 'rejects traversal and network path syntax' {
        (Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot (Join-Path $sandbox '../escape')).exitCode | Should -Be 2
        (Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot '\\synthetic-invalid\share').exitCode | Should -Be 2
    }
    It 'rejects invalid retention at parameter binding' {
        { Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $sandbox -RetentionDays 0 } | Should -Throw
    }
    It 'rejects unsafe manifest names before any mutation' {
        Set-Policy $sandbox $false @('../evidence.dmp')
        $before = Get-Snapshot $sandbox
        (Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $sandbox).exitCode | Should -Be 2
        (Get-Snapshot $sandbox) | Should -BeExactly $before
    }
    It 'rejects duplicate names and dumps even if explicitly listed' {
        Set-Policy $sandbox $false @('expired.tmp','expired.tmp')
        (Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $sandbox).exitCode | Should -Be 2
        Set-Policy $sandbox $false @('evidence.dmp')
        (Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $sandbox).exitCode | Should -Be 2
    }
    It 'preserves all files during investigation hold' {
        Set-Policy $sandbox $true @('expired.tmp','recent.tmp')
        $r = Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $sandbox -Confirm:$false
        $r.exitCode | Should -Be 0
        $r.succeeded | Should -Be 0
        Test-Path -LiteralPath (Join-Path $sandbox 'temp/expired.tmp') | Should -BeTrue
    }
    It 'preserves all files with an empty disposal manifest' {
        Set-Policy $sandbox $false @()
        $r = Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $sandbox -Confirm:$false
        $r.succeeded | Should -Be 0
        $r.exitCode | Should -Be 0
    }
    It 'enforces quantity and size limits before deletion' {
        (Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $sandbox -MaxFiles 1).exitCode | Should -Be 2
        (Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $sandbox -MaxFileBytes 1).exitCode | Should -Be 2
        Test-Path -LiteralPath (Join-Path $sandbox 'temp/expired.tmp') | Should -BeTrue
    }
    It 'rejects a missing synthetic marker' {
        # This mutation touches only a generated fixture marker.
        Remove-Item -LiteralPath (Join-Path $sandbox '.synthetic-maintenance-sandbox')
        (Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $sandbox).exitCode | Should -Be 2
    }
    It 'rejects a junction without traversing its target' {
        $other = & $fixture
        $before = Get-Snapshot $other
        New-Item -ItemType Junction -Path (Join-Path $sandbox 'temp/link') -Target $other | Out-Null
        (Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $sandbox).exitCode | Should -Be 2
        (Get-Snapshot $other) | Should -BeExactly $before
    }
    It 'simulates permission denial without altering ACLs or deleting the file' {
        Mock Remove-MaintenanceFile -ModuleName SafeMaintenance { throw [UnauthorizedAccessException]::new('SIMULATED_PERMISSION_DENIED') }
        $r = Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $sandbox -Confirm:$false
        $r.exitCode | Should -Be 3
        $r.failed | Should -Be 1
        $r.succeeded | Should -Be 0
        Test-Path -LiteralPath (Join-Path $sandbox 'temp/expired.tmp') | Should -BeTrue
    }
    It 'reports partial failures and verifies the independent successful removal' {
        $second = Join-Path $sandbox 'temp/second.tmp'
        [IO.File]::WriteAllText($second, 'SYNTHETIC PARTIAL FAILURE FIXTURE')
        [IO.File]::SetLastWriteTimeUtc($second, [datetime]::UtcNow.AddDays(-30))
        Set-Policy $sandbox $false @('expired.tmp','second.tmp')
        Mock Remove-MaintenanceFile -ModuleName SafeMaintenance {
            param($LiteralPath)
            if ([IO.Path]::GetFileName($LiteralPath) -eq 'expired.tmp') { throw 'SIMULATED_FAILURE' }
            Remove-Item -LiteralPath $LiteralPath -ErrorAction Stop
        }
        $r = Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $sandbox -Confirm:$false
        $r.exitCode | Should -Be 3
        $r.succeeded | Should -Be 1
        $r.failed | Should -Be 1
        Test-Path -LiteralPath $second | Should -BeFalse
    }
    It 'detects a deletion command that returns without removing the file' {
        Mock Remove-MaintenanceFile -ModuleName SafeMaintenance { }
        $r = Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $sandbox -Confirm:$false
        $r.exitCode | Should -Be 3
        $r.succeeded | Should -Be 0
    }
    It 'stops before cleanup when audit writing fails' {
        Mock Write-MaintenanceRecord -ModuleName SafeMaintenance { throw 'SIMULATED_AUDIT_FAILURE' }
        $r = Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $sandbox -Confirm:$false
        $r.exitCode | Should -Be 5
        $r.succeeded | Should -Be 0
        Test-Path -LiteralPath (Join-Path $sandbox 'temp/expired.tmp') | Should -BeTrue
    }
    It 'does not acquire the lock even when WhatIf encounters an existing owner' {
        $handle = [IO.File]::Open((Join-Path $sandbox '.maintenance.lock'), 'Open', 'ReadWrite', 'None')
        try { (Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $sandbox -WhatIf).exitCode | Should -Be 0 }
        finally { $handle.Dispose() }
    }
    It 'rejects concurrent ownership and succeeds after the owner releases the lock' {
        $job = Start-Job -ArgumentList $sandbox -ScriptBlock {
            param($root)
            $handle = [IO.File]::Open((Join-Path $root '.maintenance.lock'), 'Open', 'ReadWrite', 'None')
            try {
                [IO.File]::WriteAllText((Join-Path $root 'owner-ready'), 'SYNTHETIC LOCK OWNER')
                $deadline = [datetime]::UtcNow.AddSeconds(25)
                while (-not (Test-Path -LiteralPath (Join-Path $root 'owner-release')) -and [datetime]::UtcNow -lt $deadline) {
                    Start-Sleep -Milliseconds 100
                }
            } finally { $handle.Dispose() }
        }
        try {
            $deadline = [datetime]::UtcNow.AddSeconds(15)
            while (-not (Test-Path -LiteralPath (Join-Path $sandbox 'owner-ready')) -and [datetime]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 100 }
            Test-Path -LiteralPath (Join-Path $sandbox 'owner-ready') | Should -BeTrue
            $r = Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $sandbox -Confirm:$false
            $r.exitCode | Should -Be 4
            $r.succeeded | Should -Be 0
        } finally {
            [IO.File]::WriteAllText((Join-Path $sandbox 'owner-release'), 'SYNTHETIC RELEASE')
            $job | Wait-Job -Timeout 30 | Out-Null
            $job | Remove-Job -Force
        }
        (Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $sandbox -Confirm:$false).exitCode | Should -Be 0
    }
    It 'writes valid JSON Lines with intent before success and a reconciled summary' {
        $r = Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $sandbox -Confirm:$false
        $records = @(Get-Content -LiteralPath (Join-Path $sandbox $r.audit) | ForEach-Object { $_ | ConvertFrom-Json })
        $records.Count | Should -Be 7
        foreach ($record in $records) {
            $record.schema | Should -Be 'h3.event.v1'
            $record.runId | Should -Be $r.runId
            { [datetime]::Parse($record.timestampUtc) } | Should -Not -Throw
        }
        $removals = @($records | Where-Object { $_.action -eq 'remove' })
        $removals[0].status | Should -Be 'intent'
        $removals[0].sha256 | Should -Match '^[A-F0-9]{64}$'
        $removals[1].status | Should -Be 'succeeded'
        ($records | Where-Object { $_.reason -eq 'recent' }).file | Should -Be 'temp/recent.tmp'
        $records[-1].summary.succeeded | Should -Be $r.succeeded
        $records[-1].summary.skipped | Should -Be $r.skipped
        $records[-1].summary.exitCode | Should -Be 0
        (Get-Content -LiteralPath (Join-Path $sandbox $r.audit) -Raw) | Should -Not -Match ([regex]::Escape($repo))
    }
    It 'returns actual process exit codes for valid invalid and binding cases' {
        $raw = & $engine -NoProfile -NonInteractive -File $cli -ConfigurationPath $configPath -SandboxRoot $sandbox
        $LASTEXITCODE | Should -Be 0
        ($raw | ConvertFrom-Json).exitCode | Should -Be 0
        $raw = & $engine -NoProfile -NonInteractive -File $cli -ConfigurationPath $configPath -SandboxRoot (Join-Path $sandbox 'absent')
        $LASTEXITCODE | Should -Be 2
        ($raw | ConvertFrom-Json).exitCode | Should -Be 2
        $previousPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            & $engine -NoProfile -NonInteractive -File $cli -ConfigurationPath $configPath -SandboxRoot $sandbox -RetentionDays 0 2>$null
            $LASTEXITCODE | Should -Be 1
        } finally { $ErrorActionPreference = $previousPreference }
    }
    It 'returns process code 4 for a held lock' {
        $handle = [IO.File]::Open((Join-Path $sandbox '.maintenance.lock'), 'Open', 'ReadWrite', 'None')
        try {
            $raw = & $engine -NoProfile -NonInteractive -File $cli -ConfigurationPath $configPath -SandboxRoot $sandbox
            $LASTEXITCODE | Should -Be 4
            ($raw | ConvertFrom-Json).exitCode | Should -Be 4
        } finally { $handle.Dispose() }
    }
    It 'returns process code 3 for a fixture file locked against deletion' {
        $handle = [IO.File]::Open((Join-Path $sandbox 'temp/expired.tmp'), 'Open', 'Read', 'Read')
        try {
            $raw = & $engine -NoProfile -NonInteractive -File $cli -ConfigurationPath $configPath -SandboxRoot $sandbox
            $LASTEXITCODE | Should -Be 3
            ($raw | ConvertFrom-Json).succeeded | Should -Be 0
        } finally { $handle.Dispose() }
    }
    It 'returns process code 5 when the fixture lock is read-only' {
        $file = Get-Item -LiteralPath (Join-Path $sandbox '.maintenance.lock')
        $file.IsReadOnly = $true
        try {
            $raw = & $engine -NoProfile -NonInteractive -File $cli -ConfigurationPath $configPath -SandboxRoot $sandbox
            $LASTEXITCODE | Should -Be 5
            ($raw | ConvertFrom-Json).exitCode | Should -Be 5
        } finally { $file.IsReadOnly = $false }
    }
    It 'CLI WhatIf preserves the whole tree including audit and lock metadata' {
        $before = Get-Snapshot $sandbox
        & $engine -NoProfile -NonInteractive -File $cli -ConfigurationPath $configPath -SandboxRoot $sandbox -WhatIf | Out-Null
        $LASTEXITCODE | Should -Be 0
        (Get-Snapshot $sandbox) | Should -BeExactly $before
    }
    It 'fails closed for malformed JSON' {
        [IO.File]::WriteAllText((Join-Path $sandbox 'disposable.json'), '{SYNTHETIC_INVALID_JSON')
        $before = Get-Snapshot $sandbox
        (Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $sandbox).exitCode | Should -Be 2
        (Get-Snapshot $sandbox) | Should -BeExactly $before
    }
    It 'rejects a junction used as the sandbox root' {
        $link = Join-Path (Split-Path $sandbox -Parent) ('link-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Junction -Path $link -Target $sandbox | Out-Null
        $before = Get-Snapshot $sandbox
        (Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $link).exitCode | Should -Be 2
        (Get-Snapshot $sandbox) | Should -BeExactly $before
    }

    It 'authorizes only the exact configured root, not siblings or descendants' {
        $other = & $fixture
        (Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $other).exitCode | Should -Be 2
        (Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot (Join-Path $sandbox 'temp')).exitCode | Should -Be 2
        (Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $sandbox -WhatIf).exitCode | Should -Be 0
    }
    It 'rejects disabled configuration without modifying the sandbox' {
        $cfg = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
        $cfg.enabled = $false
        $cfg | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding UTF8
        $before = Get-Snapshot $sandbox
        (Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $sandbox).exitCode | Should -Be 2
        (Get-Snapshot $sandbox) | Should -BeExactly $before
    }
    It 'rejects unknown fields, duplicate keys, wrong schema and wrong types' {
        $valid = Get-Content -LiteralPath $configPath -Raw
        foreach ($invalid in @(
            $valid.Replace('"schema":', '"unexpected": true, "schema":'),
            $valid.Replace('"schema":', '"schema": "duplicate", "schema":'),
            $valid.Replace('h3.routes.v1', 'h3.routes.v99'),
            $valid.Replace('true', '"true"')
        )) {
            [IO.File]::WriteAllText($configPath, $invalid)
            (Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $sandbox).exitCode | Should -Be 2
        }
    }
    It 'rejects drive roots UNC traversal wildcards and alternate streams in route policy' {
        $cfg = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
        foreach ($bad in @('C:\','\\synthetic-invalid\share','work-private/../escape','work-private/*','work-private/[a]','work-private/name:stream')) {
            $cfg.managedRoot = $bad
            $cfg | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding UTF8
            (Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $bad).exitCode | Should -Be 2
        }
    }
    It 'rejects a laboratory root outside its configured laboratory boundary' {
        $cfg = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
        $cfg.managedRoot = 'work-private/elsewhere'
        $cfg | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding UTF8
        (Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot (Join-Path $repo 'work-private/elsewhere')).exitCode | Should -Be 2
    }
    It 'requires matching marker content even when the root is authorized' {
        [IO.File]::WriteAllText((Join-Path $sandbox '.synthetic-maintenance-sandbox'), 'WRONG_SYNTHETIC_MARKER')
        (Invoke-SafeMaintenance -ConfigurationPath $configPath -SandboxRoot $sandbox).exitCode | Should -Be 2
    }
    It 'rejects configuration loaded through a reparse ancestor' {
        $link = Join-Path (Split-Path $sandbox -Parent) ('policy-link-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Junction -Path $link -Target $sandbox | Out-Null
        (Invoke-SafeMaintenance -ConfigurationPath (Join-Path $link 'maintenance.routes.json') -SandboxRoot $sandbox).exitCode | Should -Be 2
    }
    It 'exercises deployment path resolution only with a synthetic policy and synthetic files' {
        # Never load or invoke the WEB-PAGOS-01 example as runtime configuration.
        $cfg = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
        $cfg.mode = 'deployment'
        $cfg.computerName = $env:COMPUTERNAME
        $cfg.managedRoot = $sandbox
        $cfg.laboratoryBoundary = $null
        $cfg | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding UTF8
        $before = Get-Snapshot $sandbox
        (Invoke-SafeMaintenance -ConfigurationPath $configPath -ManagedRoot $sandbox -WhatIf).exitCode | Should -Be 0
        (Get-Snapshot $sandbox) | Should -BeExactly $before
        (Invoke-SafeMaintenance -ConfigurationPath $configPath -ManagedRoot $sandbox -Confirm:$false).succeeded | Should -Be 1
        $cfg.computerName = 'SYNTHETIC-WRONG-HOST'
        $cfg | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding UTF8
        (Invoke-SafeMaintenance -ConfigurationPath $configPath -ManagedRoot $sandbox).exitCode | Should -Be 2
    }
    It 'checks the deployment example as data only, disabled and free of extra fields' {
        $template = Get-Content -LiteralPath (Join-Path $repo 'reto2-powershell/config/WEB-PAGOS-01.example.json') -Raw | ConvertFrom-Json
        $template.enabled | Should -BeFalse
        $template.computerName | Should -Be 'WEB-PAGOS-01'
        $template.mode | Should -Be 'deployment'
        @($template.PSObject.Properties).Count | Should -Be 8
        $template.managedRoot | Should -Be 'D:\PortalPagos\Maintenance'
    }
}
