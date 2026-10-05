#requires -Version 5.1
BeforeAll {
    $repo = Split-Path $PSScriptRoot -Parent
    $moduleDir = Join-Path $repo 'reto3-azure/modules'
    Import-Module (Join-Path $moduleDir 'H4SafeAutomation/H4SafeAutomation.psd1') -Force
    $fixture = Join-Path $PSScriptRoot 'fixtures/h4/New-H4SyntheticCase.ps1'
    function Body($a) { [pscustomobject]@{RequestBody=($a | ConvertTo-Json -Depth 15 -Compress)} }
    function Ledger($path) { Get-Content (Join-Path $path 'ledger.json') -Raw -Encoding UTF8 | ConvertFrom-Json }
    function Snapshot($path) { @(Get-ChildItem $path -File | Sort-Object Name | ForEach-Object { $_.Name + (Get-FileHash $_.FullName).Hash + $_.LastWriteTimeUtc.Ticks }) -join '|' }
}

Describe 'H4 synthetic policy and Common Alert Schema' {
    BeforeEach { $c = & $fixture }
    It 'accepts Fired with exact workspace, VM, site and pool' {
        $r = Read-H4Alert (Body $c.alert) $c.policy
        $r.status | Should -Be Fired
        $r.incident | Should -Match '^[a-f0-9]{64}$'
    }
    It 'Resolved does not request remediation' {
        $c.alert.data.essentials.monitorCondition='Resolved'
        (Read-H4Alert (Body $c.alert) $c.policy).status | Should -Be Resolved
    }
    It 'rejects legacy Activated rather than infer an adapter' {
        $c.alert.data.essentials.monitorCondition='Activated'
        { Read-H4Alert (Body $c.alert) $c.policy } | Should -Throw '*RejectedAlert*'
    }
    It 'rejects malformed JSON without exposing its content' {
        { Read-H4Alert ([pscustomobject]@{RequestBody='{broken'}) $c.policy } | Should -Throw '*RejectedAlert*'
    }
    It 'rejects oversized requests' {
        { Read-H4Alert ([pscustomobject]@{RequestBody=('x'*65537)}) $c.policy } | Should -Throw '*RejectedAlert*'
    }
    It 'rejects a different subscription target' {
        $c.alert.data.essentials.alertTargetIDs[0] = $c.alert.data.essentials.alertTargetIDs[0].Replace('11111111','99999999')
        { Read-H4Alert (Body $c.alert) $c.policy } | Should -Throw
    }
    It 'rejects a different resource group' {
        $c.alert.data.alertContext.condition.allOf[0].dimensions[0].value = $c.alert.data.alertContext.condition.allOf[0].dimensions[0].value.Replace('rg-h4-observabilidad','rg-other')
        { Read-H4Alert (Body $c.alert) $c.policy } | Should -Throw
    }
    It 'rejects another VM' {
        $c.alert.data.alertContext.condition.allOf[0].dimensions[0].value = $c.alert.data.alertContext.condition.allOf[0].dimensions[0].value.Replace('vm-h4-iis','vm-other')
        { Read-H4Alert (Body $c.alert) $c.policy } | Should -Throw
    }
    It 'rejects another site' {
        $c.alert.data.alertContext.condition.allOf[0].dimensions[1].value='OtherSite'
        { Read-H4Alert (Body $c.alert) $c.policy } | Should -Throw
    }
    It 'rejects pool injection' {
        $c.alert.data.alertContext.condition.allOf[0].dimensions[2].value="H4LabPool'; exit"
        { Read-H4Alert (Body $c.alert) $c.policy } | Should -Throw
    }
    It 'rejects missing or duplicate dimensions' {
        $c.alert.data.alertContext.condition.allOf[0].dimensions[2]=$c.alert.data.alertContext.condition.allOf[0].dimensions[1]
        { Read-H4Alert (Body $c.alert) $c.policy } | Should -Throw
    }
    It 'rejects wrong rule even with correct resources' {
        $c.alert.data.essentials.alertRule='another-rule'
        { Read-H4Alert (Body $c.alert) $c.policy } | Should -Throw
    }
    It 'rejects multiple targets' {
        $c.alert.data.essentials.alertTargetIDs += 'another-target'
        { Read-H4Alert (Body $c.alert) $c.policy } | Should -Throw
    }
    It 'rejects stale alerts' {
        $c.alert.data.essentials.firedDateTime=[datetime]::UtcNow.AddMinutes(-16).ToString('o')
        { Read-H4Alert (Body $c.alert) $c.policy } | Should -Throw
    }
    It 'rejects future alerts' {
        $c.alert.data.essentials.firedDateTime=[datetime]::UtcNow.AddMinutes(2).ToString('o')
        { Read-H4Alert (Body $c.alert) $c.policy } | Should -Throw
    }
    It 'disabled policy ignores requests' {
        $c.policy.enabled=$false
        (Read-H4Alert (Body $c.alert) $c.policy).status | Should -Be Disabled
    }
    It 'maintenance ignores requests' {
        $c.policy.maintenance=$true
        (Read-H4Alert (Body $c.alert) $c.policy).status | Should -Be Disabled
    }
    It 'rejects placeholders before any integration' {
        $p = Get-Content (Join-Path $repo 'reto3-azure/config/H4.example.json') -Raw | ConvertFrom-Json
        $p.enabled | Should -BeFalse
        { Assert-H4Policy $p } | Should -Throw '*SubscriptionRequired*'
    }
    It 'rejects additional policy fields' {
        $c.policy | Add-Member arbitraryCommand 'noop'
        { Assert-H4Policy $c.policy } | Should -Throw '*PolicySchema*'
    }
    It 'rejects arbitrary HTTP destination and greater attempt limit' {
        $c.policy.uri='https://example.invalid'
        { Assert-H4Policy $c.policy } | Should -Throw
        $c.policy.uri='http://127.0.0.1:8080/health.txt';$c.policy.maxAttempts=3
        { Assert-H4Policy $c.policy } | Should -Throw
    }
}

Describe 'H4 synthetic guest effects and persistent safety' {
    BeforeEach {
        $c = & $fixture
        $sim = @{state='Stopped';starts=0;code=200;body='H4_OK';fail=$false;site='H4LabSite';pool='H4LabPool';binding=$true}
        $get = { [pscustomobject]@{site=$sim.site;pool=$sim.pool;bindingValid=$sim.binding;state=$sim.state} }.GetNewClosure()
        $start = { $sim.starts++; if ($sim.fail) {throw 'SyntheticStartDenied'}; $sim.state='Started' }.GetNewClosure()
        $probe = { [pscustomobject]@{statusCode=$sim.code;body=$sim.body} }.GetNewClosure()
        $invokeParams = @{Policy=$c.policy;Incident=$c.incident;StateDirectory=$c.sandbox;GetState=$get;StartPool=$start;Probe=$probe;Confirm=$false}
    }
    It 'WhatIf neither changes files nor calls the pool adapter' {
        $before=Snapshot $c.sandbox
        (Invoke-H4Recovery @invokeParams -WhatIf).status | Should -Be WhatIf
        (Snapshot $c.sandbox) | Should -BeExactly $before
        $sim.starts | Should -Be 0
    }
    It 'recovers stopped pool and verifies HTTP body and state' {
        $r=Invoke-H4Recovery @invokeParams
        $r.status | Should -Be Recovered
        $r.attempts | Should -Be 1
        ([datetimeoffset]::Parse($r.timestampUtc) -ge [datetimeoffset]::Parse($r.startedUtc)) | Should -BeTrue
        $sim.starts | Should -Be 1
        (Ledger $c.sandbox).records[0].status | Should -Be Recovered
    }
    It 'duplicate delivery never starts a second time' {
        $null=Invoke-H4Recovery @invokeParams
        (Invoke-H4Recovery @invokeParams).status | Should -Be Duplicate
        $sim.starts | Should -Be 1
    }
    It 'does not restart an already healthy pool' {
        $sim.state='Started'
        (Invoke-H4Recovery @invokeParams).status | Should -Be AlreadyHealthy
        $sim.starts | Should -Be 0
    }
    It 'running pool with failed HTTP escalates without restart' {
        $sim.state='Started';$sim.code=503
        (Invoke-H4Recovery @invokeParams).status | Should -Be EscalationRequired
        $sim.starts | Should -Be 0
    }
    It 'HTTP 200 with wrong body is not recovery' {
        $sim.body='unexpected'
        (Invoke-H4Recovery @invokeParams).status | Should -Be EscalationRequired
        $sim.starts | Should -Be 1
    }
    It 'counts failed starts and stops after two attempts' {
        $sim.fail=$true;$sim.code=503
        $r=Invoke-H4Recovery @invokeParams
        $r.status | Should -Be AttemptsExhausted
        $r.attempts | Should -Be 2
        $sim.starts | Should -Be 2
    }
    It 'rolling limit also prevents new incident IDs bypassing two attempts' {
        $sim.fail=$true;$sim.code=503
        $null=Invoke-H4Recovery @invokeParams
        $invokeParams.Incident='b'*64
        (Invoke-H4Recovery @invokeParams).status | Should -Be AttemptsExhausted
        $sim.starts | Should -Be 2
    }
    It 'exclusive lock prevents concurrent effects' {
        $lock=[IO.File]::Open((Join-Path $c.sandbox 'recovery.lock'),'Open','ReadWrite','None')
        try { (Invoke-H4Recovery @invokeParams).status | Should -Be Busy; $sim.starts | Should -Be 0 } finally {$lock.Dispose()}
    }
    It 'crash after durable claim requires human review and cannot reset budget' {
        $invokeParams.StartPool={throw 'synthetic interruption'}
        $invokeParams.GetState={throw 'synthetic lost state'}
        {Invoke-H4Recovery @invokeParams} | Should -Throw
        $invokeParams.GetState=$get;$invokeParams.StartPool=$start
        (Invoke-H4Recovery @invokeParams).status | Should -Be EscalationRequired
        $sim.starts | Should -Be 0
    }
    It 'corrupt ledger fails closed' {
        [IO.File]::WriteAllText((Join-Path $c.sandbox 'ledger.json'),'{bad')
        {Invoke-H4Recovery @invokeParams} | Should -Throw
        $sim.starts | Should -Be 0
    }
    It 'missing ledger never initializes new attempt allowance' {
        $invokeParams.StateDirectory=Join-Path $c.sandbox 'missing'
        {Invoke-H4Recovery @invokeParams} | Should -Throw
        $sim.starts | Should -Be 0
        Test-Path $invokeParams.StateDirectory | Should -BeFalse
    }
    It 'wrong site to pool mapping forbids action' {
        $sim.pool='OtherPool'
        (Invoke-H4Recovery @invokeParams).status | Should -Be EscalationRequired
        $sim.starts | Should -Be 0
    }
    It 'wrong binding forbids action' {
        $sim.binding=$false
        (Invoke-H4Recovery @invokeParams).status | Should -Be EscalationRequired
        $sim.starts | Should -Be 0
    }
    It 'transitional state never starts the pool' {
        $sim.state='Starting'
        (Invoke-H4Recovery @invokeParams).status | Should -Be EscalationRequired
        $sim.starts | Should -Be 0
    }
    It 'HTTP checker rejects redirects, failures and empty content' {
        Test-H4Http 302 'H4_OK' | Should -BeFalse
        Test-H4Http 503 'H4_OK' | Should -BeFalse
        Test-H4Http 200 '' | Should -BeFalse
        Test-H4Http 200 "H4_OK`r`n" | Should -BeTrue
    }
}

Describe 'H4 probe sequence semantics (reference, not KQL execution)' {
    BeforeEach {
        $now=[datetimeoffset]::UtcNow
        $p=@([pscustomobject]@{probeId='a';timestampUtc=$now.AddSeconds(-90).ToString('o');success=$false},[pscustomobject]@{probeId='b';timestampUtc=$now.AddSeconds(-30).ToString('o');success=$false})
    }
    It 'two consecutive fresh failures trigger' { Test-H4TwoFailures $p $now | Should -BeTrue }
    It 'one failure does not trigger' { Test-H4TwoFailures @($p[1]) $now | Should -BeFalse }
    It 'duplicate is not a second observation' { Test-H4TwoFailures @($p[1],$p[1]) $now | Should -BeFalse }
    It 'a success between failures prevents trigger' { $p[1].success=$true; Test-H4TwoFailures $p $now | Should -BeFalse }
    It 'missing or stale telemetry is unknown' { Test-H4TwoFailures @() $now | Should -BeFalse; Test-H4TwoFailures $p $now.AddMinutes(4) | Should -BeFalse }
}

Describe 'H4 runbook integration with synthetic command stubs only' {
    BeforeAll {
        $oldModulePath=$env:PSModulePath
        $env:PSModulePath=$moduleDir + [IO.Path]::PathSeparator + $env:PSModulePath
        $runbook=Join-Path $repo 'reto3-azure/runbooks/Invoke-H4Remediation.ps1'
        function Get-AutomationVariable { param($Name) throw 'UnmockedAutomationForbidden' }
        function Disable-AzContextAutosave { param($Scope) throw 'UnmockedAzureForbidden' }
        function Connect-AzAccount { param([switch]$Identity,$Subscription) throw 'UnmockedAzureForbidden' }
        function Invoke-AzVMRunCommand { param($ResourceGroupName,$VMName,$CommandId,$ScriptString,$DefaultProfile) throw 'UnmockedAzureForbidden' }
    }
    AfterAll { $env:PSModulePath=$oldModulePath }
    BeforeEach {
        $c=& $fixture
        Mock Get-AutomationVariable { $c.policy | ConvertTo-Json }
        Mock Disable-AzContextAutosave { }
        Mock Connect-AzAccount { [pscustomobject]@{Context=[pscustomobject]@{Subscription=[pscustomobject]@{Id=$c.policy.subscriptionId}}} }
        Mock Invoke-AzVMRunCommand {
            $incident=(Read-H4Alert (Body $c.alert) $c.policy).incident
            [pscustomobject]@{Value=@([pscustomobject]@{Code='ComponentStatus/StdOut/succeeded';Message=(@{schema='h4.result.v1';incident=$incident;status='Recovered';attempts=1;httpStatus=200}|ConvertTo-Json -Compress)})}
        }
    }
    It 'Fired invokes only the configured VM with fixed command and hex incident' {
        $r=& $runbook -WebhookData (Body $c.alert)
        ($r | ConvertFrom-Json).status | Should -Be Recovered
        Should -Invoke Invoke-AzVMRunCommand -Times 1 -Exactly -ParameterFilter {$ResourceGroupName -eq 'rg-h4-observabilidad' -and $VMName -eq 'vm-h4-iis' -and $CommandId -eq 'RunPowerShellScript' -and $ScriptString -match "-Incident '[a-f0-9]{64}'$"}
    }
    It 'Resolved never connects to Azure or submits a command' {
        $c.alert.data.essentials.monitorCondition='Resolved'
        $null=& $runbook -WebhookData (Body $c.alert)
        Should -Invoke Connect-AzAccount -Times 0 -Exactly
        Should -Invoke Invoke-AzVMRunCommand -Times 0 -Exactly
    }
    It 'invalid resource never connects to Azure' {
        $c.alert.data.essentials.alertTargetIDs=@('bad')
        {& $runbook -WebhookData (Body $c.alert)} | Should -Throw
        Should -Invoke Connect-AzAccount -Times 0 -Exactly
    }
    It 'transport failure never resubmits an indeterminate Run Command' {
        Mock Invoke-AzVMRunCommand { throw 'SyntheticTransportFailure' }
        {& $runbook -WebhookData (Body $c.alert)} | Should -Throw
        Should -Invoke Invoke-AzVMRunCommand -Times 1 -Exactly
    }
    It 'unexpected guest output fails rather than logging arbitrary output' {
        Mock Invoke-AzVMRunCommand { [pscustomobject]@{Value=@([pscustomobject]@{Code='ComponentStatus/StdOut/succeeded';Message='not structured'})} }
        {& $runbook -WebhookData (Body $c.alert)} | Should -Throw
        Should -Invoke Invoke-AzVMRunCommand -Times 1 -Exactly
    }
    It 'attempt exhaustion becomes a failed job for human-only alert B' {
        Mock Invoke-AzVMRunCommand {
            $id=(Read-H4Alert (Body $c.alert) $c.policy).incident
            [pscustomobject]@{Value=@([pscustomobject]@{Code='ComponentStatus/StdOut/succeeded';Message=(@{schema='h4.result.v1';incident=$id;status='AttemptsExhausted';attempts=2;httpStatus=503}|ConvertTo-Json -Compress)})}
        }
        {& $runbook -WebhookData (Body $c.alert)} | Should -Throw
        Should -Invoke Invoke-AzVMRunCommand -Times 1 -Exactly
    }
    It 'claimed recovery without HTTP verification is rejected' {
        Mock Invoke-AzVMRunCommand {
            $id=(Read-H4Alert (Body $c.alert) $c.policy).incident
            [pscustomobject]@{Value=@([pscustomobject]@{Code='ComponentStatus/StdOut/succeeded';Message=(@{schema='h4.result.v1';incident=$id;status='Recovered';attempts=1;httpStatus=503}|ConvertTo-Json -Compress)})}
        }
        {& $runbook -WebhookData (Body $c.alert)} | Should -Throw
        Should -Invoke Invoke-AzVMRunCommand -Times 1 -Exactly
    }
}

Describe 'H4 static deployment boundary' {
    It 'fault injection waits for the asynchronous pool stop with a bounded timeout' {
        $fault=Get-Content (Join-Path $repo 'reto3-azure/scripts/Invoke-H4LabFault.ps1') -Raw
        $fault | Should -Match "AddSeconds\(15\)"
        $fault | Should -Match "Start-Sleep -Milliseconds 250"
        $fault | Should -Match 'while \(\[datetime\]::UtcNow -lt \$deadline\)'
        $fault | Should -Match 'if \(\$state -ne ''Stopped''\) \{ throw ''StopNotVerified'' \}'
    }
    It 'all delivered PowerShell artifacts parse on this engine' {
        $files=@(Get-ChildItem (Join-Path $repo 'reto3-azure') -Recurse -File | Where-Object {$_.Extension -in '.ps1','.psm1','.psd1'})
        foreach ($file in $files) {
            $tokens=$null;$errors=$null
            $null=[Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$errors)
            @($errors).Count | Should -Be 0 -Because $file.Name
        }
    }
    It 'custom role has only the three reviewed actions, no wildcard or Contributor' {
        $r=Get-Content (Join-Path $repo 'reto3-azure/roles/H4-RunCommand-LabVM.example.json') -Raw | ConvertFrom-Json
        $r.Actions.Count | Should -Be 3
        $r.Actions | Should -Contain 'Microsoft.Compute/virtualMachines/runCommand/action'
        ($r|ConvertTo-Json -Depth 5) | Should -Not -Match '\*|Contributor'
    }
    It 'VM template declares only the reviewed VM and references the existing NIC' {
        $t=Get-Content (Join-Path $repo 'reto3-azure/arm/vm-h4.json') -Raw | ConvertFrom-Json
        @($t.resources).Count | Should -Be 1
        $vm=$t.resources[0]
        $vm.type | Should -BeExactly 'Microsoft.Compute/virtualMachines'
        $vm.name | Should -BeExactly "[variables('vmName')]"
        $vm.location | Should -BeExactly 'northcentralus'
        @($vm.properties.networkProfile.networkInterfaces).Count | Should -Be 1
        $vm.properties.networkProfile.networkInterfaces[0].id | Should -BeExactly "[resourceId('Microsoft.Network/networkInterfaces', variables('nicName'))]"
        $vm.properties.networkProfile.networkInterfaces[0].properties.deleteOption | Should -BeExactly 'Detach'
        @($t.resources | Where-Object {$_.type -match 'networkInterfaces|publicIPAddresses|networkSecurityGroups|virtualNetworks'}).Count | Should -Be 0
    }
    It 'VM template fixes the approved compute, image, disk and managed identity' {
        $t=Get-Content (Join-Path $repo 'reto3-azure/arm/vm-h4.json') -Raw | ConvertFrom-Json
        $vm=$t.resources[0]
        $vm.identity.type | Should -BeExactly 'SystemAssigned'
        $vm.properties.hardwareProfile.vmSize | Should -BeExactly 'Standard_B2als_v2'
        $vm.properties.storageProfile.imageReference.publisher | Should -BeExactly 'MicrosoftWindowsServer'
        $vm.properties.storageProfile.imageReference.offer | Should -BeExactly 'WindowsServer'
        $vm.properties.storageProfile.imageReference.sku | Should -BeExactly '2022-datacenter-azure-edition'
        $vm.properties.storageProfile.osDisk.name | Should -BeExactly "[variables('osDiskName')]"
        $vm.properties.storageProfile.osDisk.managedDisk.storageAccountType | Should -BeExactly 'StandardSSD_LRS'
        $vm.properties.storageProfile.osDisk.deleteOption | Should -BeExactly 'Delete'
        @($t.resources | Where-Object {$_.type -match 'extensions'}).Count | Should -Be 0
    }
    It 'VM template requires Portal-only credentials and stores no defaults' {
        $t=Get-Content (Join-Path $repo 'reto3-azure/arm/vm-h4.json') -Raw | ConvertFrom-Json
        $t.parameters.adminUsername.type | Should -BeExactly 'string'
        $t.parameters.adminPassword.type | Should -BeExactly 'secureString'
        $t.parameters.adminUsername.PSObject.Properties.Name | Should -Not -Contain 'defaultValue'
        $t.parameters.adminPassword.PSObject.Properties.Name | Should -Not -Contain 'defaultValue'
        $t.resources[0].properties.osProfile.adminUsername | Should -BeExactly "[parameters('adminUsername')]"
        $t.resources[0].properties.osProfile.adminPassword | Should -BeExactly "[parameters('adminPassword')]"
    }
    It 'AMA template declares exactly one extension and no DCR association' {
        $t=Get-Content (Join-Path $repo 'reto3-azure/arm/ama-h4.json') -Raw | ConvertFrom-Json
        @($t.resources).Count | Should -Be 1
        $a=$t.resources[0]
        $a.type | Should -BeExactly 'Microsoft.Compute/virtualMachines/extensions'
        $a.name | Should -BeExactly 'vm-h4-iis/AzureMonitorWindowsAgent'
        $a.location | Should -BeExactly 'northcentralus'
        $a.properties.publisher | Should -BeExactly 'Microsoft.Azure.Monitor'
        $a.properties.type | Should -BeExactly 'AzureMonitorWindowsAgent'
        $a.properties.enableAutomaticUpgrade | Should -BeTrue
        @($t.resources | Where-Object {$_.type -match 'dataCollectionRuleAssociations'}).Count | Should -Be 0
    }
}
