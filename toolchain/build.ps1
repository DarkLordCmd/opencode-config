[CmdletBinding()]
param(
    [switch]$NoCache,
    [switch]$WithMsf,
    [switch]$SkipCheck
)

$ErrorActionPreference = 'Stop'
$here = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'docker\kali'
if (-not (Test-Path (Join-Path $here 'Dockerfile'))) {
    throw "Dockerfile not found in build context: $here"
}
$log = 'E:\pintest\tmp\build.log'
New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw 'docker not found in PATH'
}

# No -f: Docker Desktop on Windows fails to read an explicit -f path from a non-system
# drive context (transfers 2 bytes and reports "open Dockerfile: no such file or directory").
# The context root contains exactly one Dockerfile, so the default resolution is correct.
$buildArgs = @('build', '--progress=plain', '-t', 'pt/kali:latest')
if ($NoCache) { $buildArgs += '--no-cache' }
if ($WithMsf) { $buildArgs += @('--build-arg', 'WITH_MSF=true') }
$buildArgs += '.'

Write-Host "[*] building pt/kali:latest (full log: $log)" -ForegroundColor Cyan
$sw = [Diagnostics.Stopwatch]::StartNew()

# Context must be relative to the Dockerfile directory: Docker Desktop on Windows cannot
# resolve an absolute -f path on a non-system drive.
Push-Location $here
# PowerShell 5.1 Push-Location updates $PWD but not the process working directory that
# native processes inherit. Without this line docker.exe looks for the Dockerfile in the
# caller's directory and builds from a 2-byte empty context.
[Environment]::CurrentDirectory = (Get-Location).Path
$ErrorActionPreference = 'Continue'
& docker @buildArgs 2>&1 | Tee-Object -FilePath $log | ForEach-Object {
    $line = $_.ToString()
    if ($line -match '^(ok|MISS|go)\s') { Write-Host $line }
    elseif ($line -match '^#[0-9]+ (DONE|ERROR)') { Write-Host $line -ForegroundColor DarkGray }
}
$code = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
Pop-Location
$sw.Stop()

if ($code -ne 0) {
    Write-Host "[-] build failed after $([math]::Round($sw.Elapsed.TotalMinutes,1)) min - see $log" -ForegroundColor Red
    exit 1
}

Write-Host ("[+] build ok in {0:n1} min" -f $sw.Elapsed.TotalMinutes) -ForegroundColor Green
if (-not $SkipCheck) {
    Write-Host '[*] verifying toolchain' -ForegroundColor Cyan
    & docker run --rm pt/kali:latest /usr/local/bin/pt-check
}
