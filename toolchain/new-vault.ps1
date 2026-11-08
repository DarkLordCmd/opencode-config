# Creates the loot container. Passphrase is typed at a masked prompt and passed only
# to the VeraCrypt Format process — not written to disk, history, or logs.
#
#   powershell -ExecutionPolicy Bypass -File E:\pintest\tools\new-vault.ps1
#   ... -Path E:\pintest\loot\vault.hc -Size 50G
#
# Why the argument string is built by hand: PowerShell 5.1's Start-Process -ArgumentList joins
# an array with spaces and does NOT quote elements. A passphrase containing a space or a token
# starting with '/' then splits into several arguments, VeraCrypt opens a modal dialog, and the
# container is never created (exit code still 0). Building one explicitly quoted string avoids it.
#
# Note: VeraCrypt has no stdin password option on Windows, so the plaintext exists in the child
# process command line for the duration of creation. A process auditor can see it. The GUI wizard
# (run "VeraCrypt Format.exe" with no arguments) avoids that entirely if it matters.

param(
    [string]$Path = 'E:\pintest\loot\vault.hc',
    [string]$Size = '20G',
    [string]$Encryption = 'AES',
    [string]$Hash = 'sha512',
    [string]$Filesystem = 'ExFAT'
)

$ErrorActionPreference = 'Stop'
$fmt = 'C:\Program Files\VeraCrypt\VeraCrypt Format.exe'

if (-not (Test-Path $fmt)) { throw "VeraCrypt Format.exe not found: $fmt" }

if (Test-Path $Path) {
    if ((Get-Item $Path).Length -eq 0) {
        Write-Host "[!] removing empty leftover: $Path"
        Remove-Item $Path -Force
    }
    else {
        Write-Host ("[-] container already exists: {0} ({1:n2} GB)" -f $Path, ((Get-Item $Path).Length / 1GB))
        exit 1
    }
}

Write-Host ""
Write-Host "  container : $Path"
Write-Host "  size      : $Size"
Write-Host "  crypto    : $Encryption / $Hash / $Filesystem"
Write-Host ""
Write-Host "  Passphrase: 20+ characters. Avoid the double-quote character." -ForegroundColor Yellow
Write-Host "  There is no recovery. Store the phrase in a password manager." -ForegroundColor Yellow
Write-Host ""

$s1 = Read-Host -AsSecureString 'Passphrase'
$s2 = Read-Host -AsSecureString 'Repeat passphrase'

$b1 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($s1)
$b2 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($s2)
$p1 = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($b1)
$p2 = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($b2)

$exit = $null
try {
    if ($p1 -ne $p2) { Write-Host '[-] passphrases do not match' -ForegroundColor Red; exit 1 }
    if ($p1.Length -lt 20) { Write-Host '[-] passphrase shorter than 20 characters' -ForegroundColor Red; exit 1 }
    if ($p1.Contains('"')) { Write-Host '[-] double quote is not allowed in the passphrase' -ForegroundColor Red; exit 1 }

    $argstr = '/create "' + $Path + '" /size ' + $Size +
              ' /encryption ' + $Encryption + ' /hash ' + $Hash + ' /filesystem ' + $Filesystem +
              ' /quick /silent /force /password "' + $p1 + '"'

    Write-Host '[*] creating container...' -ForegroundColor Cyan
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $proc = Start-Process -FilePath $fmt -ArgumentList $argstr -Wait -PassThru
    $exit = $proc.ExitCode
    $sw.Stop()
    Write-Host ("[*] format exit code: {0} in {1:n0}s" -f $exit, $sw.Elapsed.TotalSeconds)
}
finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b1)
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b2)
    $p1 = $null; $p2 = $null; $s1 = $null; $s2 = $null
    [GC]::Collect()
}

if (-not (Test-Path $Path)) {
    Write-Host '[-] container was not created.' -ForegroundColor Red
    Write-Host '    VeraCrypt under /silent exits 0 even on failure. Retry without /silent to see the dialog:' -ForegroundColor Yellow
    Write-Host ('    & "' + $fmt + '" /create "' + $Path + '" /size ' + $Size + ' /encryption ' + $Encryption + ' /hash ' + $Hash + ' /filesystem ' + $Filesystem + ' /quick') -ForegroundColor DarkGray
    exit 1
}

# VeraCrypt's header is encrypted, so there is no plaintext magic to verify. Size is the only
# offline check; mounting is the real proof.
$f = Get-Item $Path
Write-Host ""
Write-Host ("[+] created : {0}" -f $Path) -ForegroundColor Green
Write-Host ("[+] size    : {0:n2} GB ({1:n0} bytes)" -f ($f.Length / 1GB), $f.Length)
Write-Host ("[+] format  : {0} / {1} / {2}" -f $Encryption, $Hash, $Filesystem)
Write-Host ""
Write-Host '  verify by mounting (UAC for the driver):'
Write-Host ('    & "C:\Program Files\VeraCrypt\VeraCrypt.exe" /q /v "' + $Path + '" /l V')
Write-Host '    & "C:\Program Files\VeraCrypt\VeraCrypt.exe" /q /d V'
