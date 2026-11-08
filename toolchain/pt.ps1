[CmdletBinding()]
param(
    [string]$Cmd,
    [string]$Lhost,
    [switch]$Privileged,
    [switch]$Clean,
    [string]$Image = 'pt/kali:latest',
    [string]$Root = 'E:\pintest'
)

# Offensive toolchain entry point. Everything runs inside pt/kali; nothing is installed on Windows.
#   pt.ps1                      -> interactive shell
#   pt.ps1 -Cmd "nmap -sV x"    -> one command
#   pt.ps1 -Privileged          -> full caps (ligolo TUN, raw sockets beyond NET_RAW)
#   pt.ps1 -Cmd pt-check        -> verify toolchain

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { throw 'docker not found in PATH' }

& docker image inspect $Image *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[-] image $Image not found. Build it first:" -ForegroundColor Red
    Write-Host "    powershell -ExecutionPolicy Bypass -File `"E:\pintest\tools\build.ps1`"" -ForegroundColor Yellow
    exit 1
}
if (-not (Test-Path $Root)) { Write-Host "[-] engagement root missing: $Root" -ForegroundColor Red; exit 1 }

# A docker run whose client was killed (timeout, closed terminal) leaves a container holding
# the published ports, which then blocks every later run with "port is already allocated".
if ($Clean) {
    $stale = & docker ps -aq --filter "ancestor=$Image"
    if ($stale) { & docker rm -f @stale | Out-Null; Write-Host "[*] removed stale pt containers" -ForegroundColor Yellow }
}

# LHOST: address targets use to call back. Detected from the interface holding the default
# route; override with -Lhost when the engagement egresses through a VPN/tunnel adapter.
if (-not $Lhost) {
    $ifIndex = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
                Sort-Object RouteMetric | Select-Object -First 1).InterfaceIndex
    $Lhost = (Get-NetIPAddress -InterfaceIndex $ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
              Select-Object -First 1).IPAddress
}
if (-not $Lhost) { $Lhost = '<set -Lhost>' }

$runArgs = @(
    'run', '--rm', '-i'
    '-v', "${Root}:/pintest"
    '-w', '/pintest'
    '-e', 'PINTEST_HOME=/pintest'
    '-e', "LHOST=$Lhost"
    '--add-host', 'host.docker.internal:host-gateway'
    # reverse-shell / listener range, web payloads, socks, ligolo
    '-p', '4444-4450:4444-4450'
    '-p', '8080:8080'
    '-p', '8000:8000'
    '-p', '9000:9000'
    '-p', '9001:9001'
    '-p', '1080:1080'
    '-p', '11601:11601'
)

if ($Privileged) {
    $runArgs += '--privileged'
} else {
    $runArgs += @('--cap-add=NET_RAW', '--cap-add=NET_ADMIN', '--cap-add=SYS_ADMIN')
}

# PATH prefix is mandatory: Debian's /etc/profile overwrites PATH for root in login shells,
# which hides pipx tools (/root/.local/bin: certipy, pypykatz) and go binaries.
$prefix = 'export PATH=/root/.local/bin:/root/go/bin:$PATH; cd /pintest; '

if ($Cmd) {
    $runArgs += @($Image, 'bash', '-c', ($prefix + $Cmd))
} else {
    $runArgs += '-t'
    $runArgs += @($Image, 'bash', '-c', ($prefix + 'exec bash -i'))
    Write-Host ''
    Write-Host "  engagement : $Root  ->  /pintest" -ForegroundColor Cyan
    Write-Host "  LHOST      : $Lhost   (use this for reverse shells)" -ForegroundColor Cyan
    Write-Host "  published  : 4444-4450, 8080, 8000, 9000, 9001, 1080, 11601" -ForegroundColor DarkGray
    Write-Host "  help       : pt-check | lsn <port> | exit" -ForegroundColor DarkGray
    Write-Host ''
}

& docker @runArgs
exit $LASTEXITCODE
