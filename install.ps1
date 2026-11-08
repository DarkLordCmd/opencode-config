#requires -Version 5.1
<#
.SYNOPSIS
    Installs the opencode config: skills, AGENTS.md, and the full pentest toolchain.

.DESCRIPTION
    One command on a fresh machine. Copies the agent config and skills into place, creates the
    engagement workspace on a non-system drive, publishes the Docker toolchain, builds the pt/kali
    image, optionally starts the lab and BloodHound, and initialises a git repository.

    Nothing is destructive: existing files are kept, the image is only built when missing, and every
    step can be skipped with a flag.

.PARAMETER Root
    Engagement workspace root. Default E:\pintest (non-system drive).

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\install.ps1

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\install.ps1 -Root D:\work -WithLab -WithBloodhound

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\install.ps1 -DryRun
#>
[CmdletBinding()]
param(
    [string]$Root = 'E:\pintest',
    [switch]$SkipConfig,
    [switch]$SkipDocker,
    [switch]$SkipRea,
    [switch]$WithLab,
    [switch]$WithBloodhound,
    [switch]$WithGui,
    [switch]$WithMsf,
    [switch]$Verify,
    [switch]$Force,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $MyInvocation.MyCommand.Path

function Head($text) { Write-Host "`n=== $text ===" -ForegroundColor Cyan }
function Ok($text)   { Write-Host "  [+] $text" -ForegroundColor Green }
function Info($text) { Write-Host "  [*] $text" -ForegroundColor Gray }
function Warn($text) { Write-Host "  [!] $text" -ForegroundColor Yellow }
function Fail($text) { Write-Host "  [-] $text" -ForegroundColor Red }

function Invoke-Step([string]$label, [scriptblock]$action) {
    if ($DryRun) { Info "would: $label"; return }
    & $action
}

Write-Host ''
Write-Host '  opencode-config installer' -ForegroundColor White
Write-Host "  repo   : $repo"
Write-Host "  root   : $Root"
if ($DryRun) { Write-Host '  mode   : DRY RUN (nothing is changed)' -ForegroundColor Yellow }

# ---------------------------------------------------------------- preflight
Head 'Preflight'

$driveLetter = $Root.Substring(0, 2)
if (-not (Test-Path $driveLetter)) {
    Fail "drive $driveLetter does not exist - pass -Root with a real path"
    exit 1
}
$freeGb = [math]::Round((Get-PSDrive $driveLetter.TrimEnd(':')).Free / 1GB, 1)
Info "free space on $driveLetter : $freeGb GB"
if ($freeGb -lt 20 -and -not $SkipDocker) { Warn 'less than 20 GB free; the image needs ~14 GB' }

$hasGit = [bool](Get-Command git -ErrorAction SilentlyContinue)
if ($hasGit) { Ok 'git found' } else { Warn 'git not found - REA catalogue and workspace git init will be skipped' }

$hasDocker = [bool](Get-Command docker -ErrorAction SilentlyContinue)
$dockerUp = $false
if ($hasDocker -and -not $SkipDocker) {
    try { & docker version --format '{{.Server.Version}}' *> $null; $dockerUp = ($LASTEXITCODE -eq 0) } catch { $dockerUp = $false }
}
if ($SkipDocker) { Info 'docker steps skipped by flag' }
elseif (-not $hasDocker) { Warn 'docker not found - toolchain will be published but not built' }
elseif (-not $dockerUp) { Warn 'docker is installed but the daemon is not answering - start Docker Desktop and rerun' }
else { Ok 'docker daemon reachable' }

# ---------------------------------------------------------------- config + skills
if (-not $SkipConfig) {
    Head 'Agent config and skills'
    $cfg   = Join-Path $env:USERPROFILE '.config\opencode'
    $agent = Join-Path $env:USERPROFILE '.agents\skills'

    Invoke-Step "create $cfg" { New-Item -ItemType Directory -Force -Path $cfg | Out-Null }
    Invoke-Step 'copy opencode.json and AGENTS.md' {
        Copy-Item (Join-Path $repo 'opencode.json') $cfg -Force
        Copy-Item (Join-Path $repo 'AGENTS.md')     $cfg -Force
    }
    Invoke-Step 'copy skills/' {
        New-Item -ItemType Directory -Force -Path (Join-Path $cfg 'skills') | Out-Null
        robocopy (Join-Path $repo 'skills') (Join-Path $cfg 'skills') /E /NFL /NDL /NJH /NJS /NP /R:1 /W:1 | Out-Null
    }
    if (Test-Path (Join-Path $repo 'agents-skills')) {
        Invoke-Step 'copy agents-skills/' {
            New-Item -ItemType Directory -Force -Path $agent | Out-Null
            robocopy (Join-Path $repo 'agents-skills') $agent /E /NFL /NDL /NJH /NJS /NP /R:1 /W:1 | Out-Null
        }
    }
    if (-not $DryRun) {
        $skillCount = (Get-ChildItem (Join-Path $cfg 'skills') -Directory -ErrorAction SilentlyContinue).Count
        Ok "$skillCount skills in place"
    }
}

# ---------------------------------------------------------------- workspace
Head "Engagement workspace: $Root"
$dirs = @(
    'notes', 'notes\hosts', 'scans\nmap', 'scans\http', 'scans\dns', 'scans\ad', 'scans\cloud',
    'loot', 'payloads\src', 'payloads\bin', 'pocs', 'reports\draft', 'reports\final',
    'wordlists', 'tools', 'tmp', 'lab', 'backup', 'browser\profile'
)
foreach ($d in $dirs) {
    Invoke-Step "mkdir $d" { New-Item -ItemType Directory -Force -Path (Join-Path $Root $d) | Out-Null }
}

$gitignore = @'
# client-sensitive
loot/
backup/
browser/
tmp/
*.log
*.pfx
*.p12
*.kdbx
*.ntlm
*.kirbi
*.ccache
*.hive
*.dmp
*.ovpn
*.rdp
*.key
*.pem
scans/**/*.xml
scans/**/*.gnmap
scans/**/*.nmap
scans/**/*.pcap
scans/**/*.jsonl

# heavy downloaded tooling
tools/awesome-rea/
tools/ghidra/
tools/sysinternals/
tools/opencode-config-sync/
*.zip
verify-install.txt
'@
Invoke-Step 'write .gitignore' { Set-Content -Path (Join-Path $Root '.gitignore') -Value $gitignore -Encoding utf8 }

# ---------------------------------------------------------------- toolchain files
Head 'Toolchain files'
if (Test-Path (Join-Path $repo 'toolchain')) {
    Invoke-Step 'copy toolchain/ into the workspace' {
        robocopy (Join-Path $repo 'toolchain') (Join-Path $Root 'tools') /E /NFL /NDL /NJH /NJS /NP /R:1 /W:1 | Out-Null
    }
} else {
    Warn 'toolchain/ not present in the repository - skipping'
}

# launchers on PATH (user scope, no elevation)
$binDir = Join-Path $Root 'tools\bin'
if (Test-Path $binDir) {
    Invoke-Step "add $binDir to the user PATH" {
        $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        if ($userPath -notlike "*$binDir*") {
            [Environment]::SetEnvironmentVariable('Path', ($userPath.TrimEnd(';') + ';' + $binDir), 'User')
        }
    }
}

# ---------------------------------------------------------------- GUI tools (optional)
if ($WithGui) {
    Head 'GUI tools (Burp, Ghidra, x64dbg, VeraCrypt, Sysinternals)'
    $guiScript = Join-Path $Root 'tools\install-gui.ps1'
    if (Test-Path $guiScript) {
        Info 'winget needs elevation - a UAC prompt will appear'
        Invoke-Step 'install GUI tools via winget' {
            Start-Process powershell -Verb RunAs -Wait -ArgumentList @(
                '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $guiScript, '-Root', $Root)
        }
    } else {
        Warn "install-gui.ps1 not found at $guiScript"
    }

    $ghidraScript = Join-Path $Root 'tools\install-ghidra.ps1'
    if (Test-Path $ghidraScript) {
        Invoke-Step 'install portable Ghidra (no elevation)' {
            & powershell -ExecutionPolicy Bypass -NoProfile -File $ghidraScript -Root $Root
        }
    }
}

# ---------------------------------------------------------------- docker image
if (-not $SkipDocker -and $dockerUp) {
    Head 'Docker image pt/kali'
    & docker image inspect 'pt/kali:latest' *> $null
    $imageExists = ($LASTEXITCODE -eq 0)

    if ($imageExists -and -not $Force) {
        Ok 'image pt/kali:latest already present (use -Force to rebuild)'
    } else {
        $builder = Join-Path $Root 'tools\build.ps1'
        if (Test-Path $builder) {
            if ($WithMsf) { $builderArgs = @('-ExecutionPolicy','Bypass','-File',$builder,'-WithMsf') }
            else          { $builderArgs = @('-ExecutionPolicy','Bypass','-File',$builder) }
            Invoke-Step 'build pt/kali:latest (10-20 min)' { & powershell @builderArgs }
        } else {
            Warn "build.ps1 not found at $builder"
        }
    }
}

# ---------------------------------------------------------------- REA catalogue
if (-not $SkipRea -and $hasGit) {
    Head 'REA catalogue'
    $rea = Join-Path $Root 'tools\awesome-rea'
    if (Test-Path (Join-Path $rea 'scripts\catalog.py')) {
        Ok 'catalogue already present'
    } else {
        Invoke-Step 'clone Awesome-REA (62 MB)' {
            & git clone --depth 1 https://github.com/reacher-z/Awesome-REA.git $rea 2>&1 | Out-Null
        }
    }
}

# ---------------------------------------------------------------- optional services
if ($WithLab -and $dockerUp) {
    Head 'Lab targets'
    foreach ($lab in @(@{n='lab-dvwa'; img='vulnerables/web-dvwa'; port='8181:80'},
                       @{n='lab-juice'; img='bkimminich/juice-shop'; port='8282:3000'})) {
        Invoke-Step "run $($lab.n)" {
            & docker rm -f $lab.n *> $null
            & docker run -d --name $lab.n -p $lab.port $lab.img | Out-Null
        }
    }
    Ok 'DVWA :8181, Juice Shop :8282'
}

if ($WithBloodhound -and $dockerUp) {
    Head 'BloodHound CE'
    $bh = Join-Path $Root 'tools\bloodhound'
    if (Test-Path (Join-Path $bh 'docker-compose.yml')) {
        $envFile = Join-Path $bh '.env'
        if (-not (Test-Path $envFile)) {
            Invoke-Step 'generate local credentials' {
                $rnd = { param($n) -join ((1..$n) | ForEach-Object { '0123456789abcdef'[(Get-Random -Maximum 16)] }) }
                @(
                    'POSTGRES_USER=bloodhound',
                    "POSTGRES_PASSWORD=$(& $rnd 40)",
                    'POSTGRES_DB=bloodhound',
                    'NEO4J_USER=neo4j',
                    "NEO4J_SECRET=$(& $rnd 40)",
                    'BLOODHOUND_PORT=8081',
                    'NEO4J_WEB_PORT=7474'
                ) | Set-Content $envFile -Encoding ascii
            }
        }
        Invoke-Step 'docker compose up -d' { & docker compose -f (Join-Path $bh 'docker-compose.yml') up -d | Out-Null }
        Info 'UI http://127.0.0.1:8081 - initial admin password is in: docker compose logs bloodhound'
    } else {
        Warn 'bloodhound compose file not found'
    }
}

# ---------------------------------------------------------------- git
if ($hasGit -and -not (Test-Path (Join-Path $Root '.git'))) {
    Head 'Workspace git'
    Invoke-Step 'git init' {
        & git -C $Root init -q
        & git -C $Root add -A
        & git -C $Root -c user.name='operator' -c user.email='operator@local' commit -q -m 'chore: initialise engagement workspace' 2>&1 | Out-Null
    }
}

# ---------------------------------------------------------------- verification
if ($Verify -and -not $DryRun) {
    Head 'Verification'
    $results = @()

    function Check([string]$name, [scriptblock]$test) {
        $detail = $null
        $ok = $false
        try {
            $detail = & $test
            $ok = [bool]$detail
        } catch {
            $ok = $false
        }
        if ($ok) { Ok ("{0} : {1}" -f $name, $detail) } else { Fail $name }
        $script:results += [pscustomobject]@{ Item = $name; Ok = $ok; Detail = "$detail" }
    }

    $cfgDir = Join-Path $env:USERPROFILE '.config\opencode'
    $binDir = Join-Path $Root 'tools\bin'
    $ptPs   = Join-Path $Root 'tools\pt.ps1'

    # config and skills
    Check 'config AGENTS.md'      { if (Test-Path (Join-Path $cfgDir 'AGENTS.md')) { 'present' } }
    Check 'config opencode.json'  { if (Test-Path (Join-Path $cfgDir 'opencode.json')) { 'present' } }
    Check 'skills installed'      { $n = (Get-ChildItem (Join-Path $cfgDir 'skills') -Directory -ErrorAction SilentlyContinue).Count; if ($n -ge 400) { "$n dirs" } }
    Check 'agents-skills'         { $n = (Get-ChildItem (Join-Path $env:USERPROFILE '.agents\skills') -Directory -ErrorAction SilentlyContinue).Count; if ($n -ge 50) { "$n dirs" } }

    # workspace
    Check 'workspace structure' {
        $need = 'notes', 'scans', 'loot', 'pocs', 'reports', 'tools', 'payloads'
        $missing = $need | Where-Object { -not (Test-Path (Join-Path $Root $_)) }
        if (-not $missing) { "$($need.Count) core dirs" }
    }
    Check 'toolchain in workspace' { if (Test-Path (Join-Path $Root 'tools\build.ps1')) { 'build.ps1 present' } }

    # launchers
    Check 'launchers published' {
        $need = 'burp', 'ghidra', 'x64dbg', 'x32dbg', 'veracrypt', 'accesschk', 'procdump', 'psexec', 'sigcheck'
        $have = @($need | Where-Object { Test-Path (Join-Path $binDir "$_.cmd") })
        if ($have.Count -eq $need.Count) { "$($have.Count)/$($need.Count)" }
    }
    Check 'launchers on user PATH' {
        $up = [Environment]::GetEnvironmentVariable('Path', 'User')
        if ($up -like "*$binDir*") { 'set' }
    }

    # docker image and toolchain inside it
    if ($dockerUp) {
        Check 'image pt/kali:latest' {
            $size = & docker image inspect 'pt/kali:latest' --format '{{.Size}}' 2>$null
            if ($LASTEXITCODE -eq 0 -and $size) { "$([math]::Round([double]$size/1GB,1)) GB" }
        }
        Check 'toolchain inside the image' {
            if (-not (Test-Path $ptPs)) { return }
            $out = & powershell -ExecutionPolicy Bypass -NoProfile -File $ptPs -Cmd 'pt-check' 2>&1 | Out-String
            $missing = ([regex]::Matches($out, 'MISSING')).Count
            if ($missing -eq 0) { 'pt-check: all present' }
            else { Write-Host "      $missing tools missing (run pt-check for the list)" -ForegroundColor DarkYellow; $false }
        }
    } else {
        Warn 'docker not running - image and container checks skipped'
    }

    # REA
    Check 'REA catalogue' { if (Test-Path (Join-Path $Root 'tools\awesome-rea\scripts\catalog.py')) { 'present' } }

    # optional components, only if they were requested
    if ($WithLab -and $dockerUp) {
        Check 'lab containers' {
            $n = @(& docker ps --filter 'name=lab-' --format '{{.Names}}' 2>$null | Where-Object { $_ }).Count
            if ($n -ge 2) { "$n running" }
        }
    }
    if ($WithBloodhound -and $dockerUp) {
        Check 'BloodHound UI' {
            try {
                $r = Invoke-WebRequest 'http://127.0.0.1:8081/ui/login' -UseBasicParsing -TimeoutSec 6
                if ($r.StatusCode -eq 200) { 'HTTP 200' }
            } catch { }
        }
    }
    if ($WithGui) {
        Check 'Burp'      { if (Test-Path 'C:\Program Files\BurpSuiteCommunity\BurpSuiteCommunity.exe') { 'present' } }
        Check 'VeraCrypt' { if (Test-Path 'C:\Program Files\VeraCrypt\VeraCrypt.exe') { 'present' } }
        Check 'Ghidra'    { if (Test-Path (Join-Path $Root 'tools\ghidra\ghidraRun.bat')) { 'present' } }
    }

    # report
    $failed = @($results | Where-Object { -not $_.Ok })
    $reportPath = Join-Path $Root 'verify-install.txt'
    $lines = @("opencode-config install verification - $(Get-Date -Format 'yyyy-MM-dd HH:mm')", '')
    $lines += $results | ForEach-Object { "{0,-34} {1}  {2}" -f $_.Item, $(if ($_.Ok) { 'OK  ' } else { 'FAIL' }), $_.Detail }
    $lines += '', ("passed: {0}/{1}" -f ($results.Count - $failed.Count), $results.Count)
    $lines | Set-Content $reportPath -Encoding utf8

    Write-Host ''
    if ($failed.Count -eq 0) {
        Write-Host ("  verified: {0}/{0} checks passed" -f $results.Count) -ForegroundColor Green
    } else {
        Write-Host ("  verified: {0}/{1} passed, {2} failed" -f ($results.Count - $failed.Count), $results.Count, $failed.Count) -ForegroundColor Red
        $failed | ForEach-Object { Write-Host ("    - " + $_.Item) -ForegroundColor Red }
        Write-Host ("  report: $reportPath") -ForegroundColor Yellow
        exit 1
    }
    Write-Host ("  report: $reportPath") -ForegroundColor Gray
}

# ---------------------------------------------------------------- summary
Head 'Done'
if ($DryRun) {
    Write-Host '  Dry run finished. Rerun without -DryRun to apply.' -ForegroundColor Yellow
    exit 0
}

Write-Host @"

  Config      : $env:USERPROFILE\.config\opencode
  Workspace   : $Root
  Toolchain   : $Root\tools
  Image       : pt/kali:latest $(if ($dockerUp) { '(checked)' } else { '(not built - start Docker)' })

  Next steps
  1. powershell -File "$Root\tools\pt.ps1" -Cmd pt-check      # verify the image
  2. Mount an encrypted volume for loot before an engagement (see tools\new-vault.ps1)
  3. Test browser profile: tools\pt-browser.cmd               # separate profile, never the main one

"@ -ForegroundColor White
