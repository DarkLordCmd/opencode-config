#requires -RunAsAdministrator
# Installs the Windows-side GUI/driver tools. Runs elevated (UAC).
# Log: E:\pintest\tmp\install-gui.log   Result marker: E:\pintest\tmp\install-gui.done
$ErrorActionPreference = 'Continue'
$log = 'E:\pintest\tmp\install-gui.log'
$done = 'E:\pintest\tmp\install-gui.done'
New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null

function Log($m) { $m | Tee-Object -FilePath $log -Append }

"" | Out-File $log -Encoding utf8
Log ("started   : " + (Get-Date -Format o))
Log ("user      : " + $env:USERNAME)
Log ("elevated  : " + ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
Log ("winget    : " + (Get-Command winget -ErrorAction SilentlyContinue).Source)

$pkgs = @(
    @{ Id = 'IDRIX.VeraCrypt';                  Args = @() },
    @{ Id = 'GoLang.Go';                        Args = @('--scope', 'machine') },
    @{ Id = 'PortSwigger.BurpSuite.Community';  Args = @() },
    @{ Id = 'x64dbg.x64dbg';                    Args = @() },
    @{ Id = 'Microsoft.Sysinternals.Suite';     Args = @() }
)

$results = @()
foreach ($p in $pkgs) {
    Log ""
    Log ("== " + $p.Id)
    $a = @('install', '--id', $p.Id, '--exact', '--silent',
           '--accept-package-agreements', '--accept-source-agreements',
           '--disable-interactivity') + $p.Args
    & winget @a *>&1 | ForEach-Object { Log $_.ToString() }
    $code = $LASTEXITCODE
    Log ("exit=" + $code)
    $results += ("{0}={1}" -f $p.Id, $code)
}

Log ""
Log "== verification"
foreach ($probe in @(
        'C:\Program Files\VeraCrypt\VeraCrypt.exe',
        'C:\Program Files\Go\bin\go.exe',
        "$env:LOCALAPPDATA\Programs\BurpSuiteCommunity\BurpSuiteCommunity.exe",
        'C:\Program Files\BurpSuiteCommunity\BurpSuiteCommunity.exe',
        'C:\Program Files\x64dbg\release\x64\x64dbg.exe',
        'C:\Program Files (x86)\SysinternalsSuite\accesschk64.exe'
    )) {
    Log ("{0} : {1}" -f $(if (Test-Path $probe) { 'OK     ' } else { 'MISSING' }), $probe)
}

$results -join "`n" | Out-File $done -Encoding utf8
Log ""
Log ("finished  : " + (Get-Date -Format o))
Log "done"
